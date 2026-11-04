import Foundation
import Primitives

public extension Equity {
    /// Opening owner capital from one supplied financial position.
    /// Positive capital corresponds to a credit (negative signed balance).
    struct Anchor: Invariant, Sendable {
        public struct Raw: Sendable {
            public let position: PositionState
            public let account: Account.Reference

            public init(position: PositionState, account: Account.Reference) {
                self.position = position
                self.account = account
            }
        }

        public enum Error: Swift.Error, Equatable, Sendable {
            case invalidAccount(Account.Reference)
            case unassignedCapital(Entity.Reference, Decimal)
        }

        public let position: PositionState
        public let account: Account.Reference
        public let amounts: [Entity.Reference: Decimal]

        public init(_ raw: Raw) throws(Error) {
            guard raw.position.chart.account(raw.account)?.category == .equity else {
                throw .invalidAccount(raw.account)
            }
            var amounts: [Entity.Reference: Decimal] = [:]
            for entity in raw.position.entities.all {
                let signed = raw.position.amount(
                    for: raw.account, entity: entity.reference
                )?.total ?? 0
                guard entity.reference.class == "person",
                      entity.reference.family == "owner" else {
                    if signed != 0 {
                        throw .unassignedCapital(entity.reference, signed)
                    }
                    continue
                }
                amounts[entity.reference] = -signed
            }
            self.position = raw.position
            self.account = raw.account
            self.amounts = amounts
        }

        public init(position: PositionState, account: Account.Reference) throws(Error) {
            try self.init(.init(position: position, account: account))
        }

        public var total: Decimal {
            amounts.values.reduce(Decimal.zero, +)
        }
    }

    /// Signed, owner-facing economic capital amounts, not journal postings.
    struct Position: Sendable {
        public let owner: Entity.Reference
        public let opening: Decimal
        public let contributions: Decimal
        public let drawings: Decimal
        public let profit: Decimal

        public var closing: Decimal {
            opening + contributions - drawings + profit
        }
    }

    /// A derived rollforward over one opening position and one profit decision.
    /// Direct capital never moves merely because ownership percentages change.
    struct Rollforward: Calculation {
        public struct Input: Sendable {
            public let anchor: Anchor
            public let allocation: Ownership.Allocation.Result
            public let contributions: Set<Account.Reference>
            public let drawings: Set<Account.Reference>

            public init(
                anchor: Anchor,
                allocation: Ownership.Allocation.Result,
                contributions: Set<Account.Reference> = [],
                drawings: Set<Account.Reference> = []
            ) {
                self.anchor = anchor
                self.allocation = allocation
                self.contributions = contributions
                self.drawings = drawings
            }
        }

        public enum Error: Swift.Error, Equatable, Sendable {
            case boundaryMismatch
            case incompatibleChart
            case incompatibleEntities
            case invalidContributionAccount(Account.Reference)
            case invalidDrawingAccount(Account.Reference)
            case unassignedMovement(Entity.Reference)
            case unassignedProfit(Entity.Reference)
            case duplicateProfit(Posting.Source)
            case unbalancedAllocation(Decimal)
        }

        public struct Movement: Sendable {
            public enum Kind: Sendable {
                case contribution
                case drawing
            }

            public let kind: Kind
            public let owner: Entity.Reference
            public let account: Account.Reference
            /// Positive contributions increase capital; positive drawings reduce it.
            public let amount: Decimal
            public let source: Posting.Source
        }

        public struct Result: Sendable {
            public let anchor: Anchor
            public let allocation: Ownership.Allocation.Result
            public let movements: [Movement]
            public let positions: [Entity.Reference: Position]

            public var opening: Decimal {
                positions.values.reduce(Decimal.zero) { $0 + $1.opening }
            }

            public var contributions: Decimal {
                positions.values.reduce(Decimal.zero) { $0 + $1.contributions }
            }

            public var drawings: Decimal {
                positions.values.reduce(Decimal.zero) { $0 + $1.drawings }
            }

            public var profit: Decimal {
                positions.values.reduce(Decimal.zero) { $0 + $1.profit }
            }

            public var closing: Decimal {
                positions.values.reduce(Decimal.zero) { $0 + $1.closing }
            }
        }

        public init() {}

        /// Classifies original journal lines once for both first-period and
        /// continued equity calculations. Never manufactures capital postings.
        /// Account selection includes the validated descendant hierarchy.
        func classifiedMovements(
            allocation: Ownership.Allocation.Result,
            contributions: Set<Account.Reference>,
            drawings: Set<Account.Reference>
        ) throws(Error) -> [Movement] {
            let period = allocation.period
            let journal = period.ledger.journal
            for account in contributions {
                guard journal.chart.account(account)?.category == .equity else {
                    throw .invalidContributionAccount(account)
                }
            }
            for account in drawings {
                guard journal.chart.account(account)?.category == .dividends else {
                    throw .invalidDrawingAccount(account)
                }
            }

            let owners = Set(allocation.ownership.portfolio.histories.map(\.owner))
            let profitSources = Set(allocation.posted.map(\.source))
            var movements: [Movement] = []
            for posting in period.movements.postings {
                let ancestors = journal.chart.ancestors(of: posting.account) ?? []
                let isContribution = contributions.contains(posting.account)
                    || ancestors.contains(where: contributions.contains)
                let isDrawing = drawings.contains(posting.account)
                    || ancestors.contains(where: drawings.contains)
                guard isContribution || isDrawing else { continue }
                guard owners.contains(posting.entity) else {
                    throw .unassignedMovement(posting.entity)
                }
                if profitSources.contains(posting.source) {
                    throw .duplicateProfit(posting.source)
                }
                if isContribution {
                    movements.append(Movement(
                        kind: .contribution,
                        owner: posting.entity,
                        account: posting.account,
                        amount: -posting.signedAmount,
                        source: posting.source
                    ))
                } else {
                    movements.append(Movement(
                        kind: .drawing,
                        owner: posting.entity,
                        account: posting.account,
                        amount: posting.signedAmount,
                        source: posting.source
                    ))
                }
            }
            return movements
        }

        public func evaluate(_ input: Input) throws(Error) -> Result {
            let period = input.allocation.period
            let journal = period.ledger.journal
            let opening = input.anchor.position
            guard opening.boundary == period.start else {
                throw .boundaryMismatch
            }
            guard opening.chart.isCompatibleForContinuity(with: journal.chart) else {
                throw .incompatibleChart
            }
            guard opening.entities.count == journal.entities.count else {
                throw .incompatibleEntities
            }
            for entity in opening.entities.all {
                guard let current = journal.entities.entity(entity.reference),
                      current.displayName == entity.displayName,
                      current.details == entity.details,
                      current.metadata == entity.metadata else {
                    throw .incompatibleEntities
                }
            }

            guard input.allocation.remainder == 0 else {
                throw .unbalancedAllocation(input.allocation.remainder)
            }
            let owners = Set(input.allocation.ownership.portfolio.histories.map(\.owner))
            let movements = try classifiedMovements(
                allocation: input.allocation,
                contributions: input.contributions,
                drawings: input.drawings
            )
            var contributions: [Entity.Reference: Decimal] = [:]
            var drawings: [Entity.Reference: Decimal] = [:]
            for movement in movements {
                switch movement.kind {
                case .contribution:
                    contributions[movement.owner, default: 0] += movement.amount
                case .drawing:
                    drawings[movement.owner, default: 0] += movement.amount
                }
            }
            for owner in input.allocation.amounts.keys where !owners.contains(owner) {
                throw .unassignedProfit(owner)
            }
            for owner in input.anchor.amounts.keys where !owners.contains(owner) {
                throw .unassignedMovement(owner)
            }

            var positions: [Entity.Reference: Position] = [:]
            for owner in owners {
                positions[owner] = Position(
                    owner: owner,
                    opening: input.anchor.amounts[owner] ?? 0,
                    contributions: contributions[owner] ?? 0,
                    drawings: drawings[owner] ?? 0,
                    profit: input.allocation.amounts[owner] ?? 0
                )
            }
            return Result(
                anchor: input.anchor,
                allocation: input.allocation,
                movements: movements,
                positions: positions
            )
        }
    }
}
