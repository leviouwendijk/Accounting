import Foundation
import Primitives

public extension Ownership {
    /// A validated, complete ownership arrangement from its first effective date.
    /// Journal entity attribution is untouched; collapse is a derived view.
    struct Structure: Invariant, Sendable {
        public struct Raw: Sendable {
            public let portfolio: Portfolio
            public let collapsing: Set<Entity.Reference>

            public init(
                portfolio: Portfolio,
                collapsing: Set<Entity.Reference> = []
            ) {
                self.portfolio = portfolio
                self.collapsing = collapsing
            }
        }

        public enum Error: Swift.Error, Equatable, Sendable {
            case emptyPortfolio
            case nonOwner(Entity.Reference)
            case unknownCollapse(Entity.Reference)
            case invalidTotal(date: Date, total: Decimal)
            case incompleteDivision(owner: Entity.Reference, date: Date, total: Decimal)
            case unknownBeneficiary(owner: Entity.Reference, recipient: Entity.Reference, date: Date)
            case inactiveBeneficiary(owner: Entity.Reference, recipient: Entity.Reference, date: Date)
            case cycle(owner: Entity.Reference, date: Date)
            case invalidEffectiveTotal(date: Date, total: Decimal)
        }

        public struct Snapshot: Sendable {
            public let start: Date
            /// Includes collapsing entities and explicitly declared zero shares.
            public let declared: [Entity.Reference: Decimal]
            /// Terminal beneficiaries after the complete division graph resolves.
            public let effective: [Entity.Reference: Decimal]
            /// Active collapse rules, retained for inspection and later attribution.
            public let routes: [Entity.Reference: [Division]]
        }

        public let portfolio: Portfolio
        public let collapsing: Set<Entity.Reference>
        public let snapshots: [Snapshot]

        public init(_ raw: Raw) throws(Error) {
            guard !raw.portfolio.histories.isEmpty else {
                throw .emptyPortfolio
            }
            for history in raw.portfolio.histories {
                guard history.owner.class == "person", history.owner.family == "owner" else {
                    throw .nonOwner(history.owner)
                }
            }
            for owner in raw.collapsing {
                guard raw.portfolio.history(for: owner) != nil else {
                    throw .unknownCollapse(owner)
                }
            }

            let dates = Set(raw.portfolio.histories.flatMap { history in
                [history.initial.effectiveFrom]
                    + history.changes.map { $0.state.effectiveFrom }
            }).sorted()

            var snapshots: [Snapshot] = []
            snapshots.reserveCapacity(dates.count)

            for date in dates {
                var declared: [Entity.Reference: Decimal] = [:]
                for history in raw.portfolio.histories {
                    if let state = history.state(at: date) {
                        declared[history.owner] = state.share.fraction
                    }
                }
                let total = declared.values.reduce(Decimal.zero, +)
                guard total == 1 else {
                    throw .invalidTotal(date: date, total: total)
                }

                var routes: [Entity.Reference: [Division]] = [:]
                for owner in raw.collapsing {
                    guard let share = declared[owner],
                          let history = raw.portfolio.history(for: owner) else {
                        continue
                    }
                    let divisions = history.divisions(at: date)
                    if share > 0 || !divisions.isEmpty {
                        let divided = divisions.reduce(Decimal.zero) {
                            $0 + $1.share.fraction
                        }
                        guard divided == 1 else {
                            throw .incompleteDivision(owner: owner, date: date, total: divided)
                        }
                        for division in divisions {
                            guard raw.portfolio.history(for: division.recipient) != nil else {
                                throw .unknownBeneficiary(
                                    owner: owner, recipient: division.recipient, date: date
                                )
                            }
                            guard declared[division.recipient] != nil else {
                                throw .inactiveBeneficiary(
                                    owner: owner, recipient: division.recipient, date: date
                                )
                            }
                        }
                        routes[owner] = divisions
                    }
                }

                var effective: [Entity.Reference: Decimal] = [:]
                func distribute(
                    _ owner: Entity.Reference,
                    amount: Decimal,
                    visited: Set<Entity.Reference>
                ) throws(Error) {
                    guard !visited.contains(owner) else {
                        throw .cycle(owner: owner, date: date)
                    }
                    guard raw.collapsing.contains(owner) else {
                        effective[owner, default: 0] += amount
                        return
                    }
                    guard let divisions = routes[owner] else {
                        throw .incompleteDivision(owner: owner, date: date, total: 0)
                    }
                    var next = visited
                    next.insert(owner)
                    for division in divisions where division.share.fraction > 0 {
                        try distribute(
                            division.recipient,
                            amount: amount * division.share.fraction,
                            visited: next
                        )
                    }
                }

                for (owner, share) in declared where share > 0 {
                    try distribute(owner, amount: share, visited: [])
                }
                let effectiveTotal = effective.values.reduce(Decimal.zero, +)
                guard effectiveTotal == 1 else {
                    throw .invalidEffectiveTotal(date: date, total: effectiveTotal)
                }
                snapshots.append(Snapshot(
                    start: date,
                    declared: declared,
                    effective: effective,
                    routes: routes
                ))
            }
            self.portfolio = raw.portfolio
            self.collapsing = raw.collapsing
            self.snapshots = snapshots
        }

        public init(
            portfolio: Portfolio,
            collapsing: Set<Entity.Reference> = []
        ) throws(Error) {
            try self.init(.init(portfolio: portfolio, collapsing: collapsing))
        }

        /// The initial date is the inception of the modeled ownership arrangement.
        /// No shares are invented for earlier dates.
        public func snapshot(at date: Date) -> Snapshot? {
            guard date.timeIntervalSinceReferenceDate.isFinite else { return nil }
            var lower = 0
            var upper = snapshots.count
            while lower < upper {
                let middle = lower + (upper - lower) / 2
                if snapshots[middle].start <= date {
                    lower = middle + 1
                } else {
                    upper = middle
                }
            }
            return lower == 0 ? nil : snapshots[lower - 1]
        }
    }
}
