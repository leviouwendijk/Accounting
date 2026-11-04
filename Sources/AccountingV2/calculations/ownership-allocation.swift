import Foundation
import Primitives

public extension Ownership {
    /// Determines owner profit entitlements without changing the journal,
    /// accepting a closing, or transferring any existing owner's capital.
    struct Allocation: Calculation {
        public enum Basis: Equatable, Sendable {
            case snapshot(Date)
            case timeline
        }

        /// Which validated ownership projection receives derived income.
        public enum Attribution: Sendable {
            case declared
            case effective
        }

        public enum MismatchPolicy: Sendable {
            case reject
            case fallback
        }

        public enum PostedPolicy: Sendable {
            case ignore
            case prefer(account: Account.Reference, mismatch: MismatchPolicy)
        }

        public struct Policy: Sendable {
            public let basis: Basis
            public let attribution: Attribution
            public let posted: PostedPolicy
            public let tolerance: Decimal

            public init(
                basis: Basis,
                attribution: Attribution = .effective,
                posted: PostedPolicy = .ignore,
                tolerance: Decimal = Decimal(1) / 100
            ) {
                self.basis = basis
                self.attribution = attribution
                self.posted = posted
                self.tolerance = tolerance
            }
        }

        public struct Input: Sendable {
            public let period: Period
            public let ownership: Structure
            public let policy: Policy

            public init(period: Period, ownership: Structure, policy: Policy) {
                self.period = period
                self.ownership = ownership
                self.policy = policy
            }
        }

        public enum Error: Swift.Error, Equatable, Sendable {
            case incompatibleEntities
            case invalidTolerance
            case invalidDate
            case unknownAccount(Account.Reference)
            case invalidPostedAccount(Account.Reference)
            case uncategorizedAccount(Account.Reference)
            case postedMismatch(Decimal)
            case missingShares(Date)
            case unassignedIncomePosting(Entry.ID)
        }

        public enum Decision: Equatable, Sendable {
            case posted
            case derived(Basis)
        }

        public struct Posted: Sendable {
            public let owner: Entity.Reference
            /// Profit is positive, loss negative; opposite the signed
            /// equity-account contribution in the original journal.
            public let amount: Decimal
            public let source: Posting.Source
        }

        public struct Segment: Sendable {
            public let start: Date
            public let end: Date
            public let netIncome: Decimal
            /// Shares used for this segment's allocation.
            public let shares: [Entity.Reference: Decimal]
            /// Both validated views remain available for inspection.
            public let declared: [Entity.Reference: Decimal]
            public let effective: [Entity.Reference: Decimal]
            public let amounts: [Entity.Reference: Decimal]
            public let sources: [Posting.Source]
        }

        public struct Result: Sendable {
            public let period: Period
            public let ownership: Structure
            /// Nil for authoritative posted allocation; derived allocation
            /// retains its selected attribution mode.
            public let attribution: Attribution?
            public let decision: Decision
            public let netIncome: Decimal
            public let amounts: [Entity.Reference: Decimal]
            public let segments: [Segment]
            public let posted: [Posted]
            /// Non-nil only if a posted source was configured and had lines.
            /// netIncome - sum(posted amounts), retained even on fallback.
            public let postedDifference: Decimal?

            public var allocatedTotal: Decimal {
                amounts.values.reduce(Decimal.zero, +)
            }

            public var remainder: Decimal {
                netIncome - allocatedTotal
            }
        }

        public init() {}

        public func evaluate(_ input: Input) throws(Error) -> Result {
            guard input.policy.tolerance >= 0 else {
                throw .invalidTolerance
            }
            let journal = input.period.ledger.journal
            let entities = input.ownership.portfolio.entities
            guard journal.entities.count == entities.count else {
                throw .incompatibleEntities
            }
            for entity in journal.entities.all {
                guard let other = entities.entity(entity.reference),
                      other.displayName == entity.displayName,
                      other.details == entity.details,
                      other.metadata == entity.metadata else {
                    throw .incompatibleEntities
                }
            }

            var netIncome = Decimal.zero
            var incomePostings: [Posting] = []
            for posting in input.period.movements.postings {
                guard let account = journal.chart.account(posting.account),
                      let category = account.category else {
                    throw .uncategorizedAccount(posting.account)
                }
                switch category {
                case .revenue, .expenses:
                    netIncome -= posting.signedAmount
                    incomePostings.append(posting)
                case .assets, .liabilities, .equity, .dividends:
                    break
                }
            }

            var posted: [Posted] = []
            var postedDifference: Decimal?
            if case .prefer(let accountReference, let mismatch) = input.policy.posted {
                guard let account = journal.chart.account(accountReference) else {
                    throw .unknownAccount(accountReference)
                }
                guard account.postable && account.category == .equity else {
                    throw .invalidPostedAccount(accountReference)
                }
                for posting in input.period.movements.postings
                    where posting.account == accountReference {
                    posted.append(Posted(
                        owner: posting.entity,
                        amount: -posting.signedAmount,
                        source: posting.source
                    ))
                }
                if !posted.isEmpty {
                    var byOwner: [Entity.Reference: Decimal] = [:]
                    for contribution in posted {
                        byOwner[contribution.owner, default: 0] += contribution.amount
                    }
                    let difference = netIncome - byOwner.values.reduce(Decimal.zero, +)
                    postedDifference = difference
                    let absolute = difference < 0 ? -difference : difference
                    if absolute <= input.policy.tolerance {
                        return Result(
                            period: input.period,
                            ownership: input.ownership,
                            attribution: nil,
                            decision: .posted,
                            netIncome: netIncome,
                            amounts: byOwner,
                            segments: [],
                            posted: posted,
                            postedDifference: difference
                        )
                    }
                    if case .reject = mismatch {
                        throw .postedMismatch(difference)
                    }
                }
            }

            let intervals: [(start: Date, end: Date)]
            switch input.policy.basis {
            case .snapshot(let date):
                guard date.timeIntervalSinceReferenceDate.isFinite else {
                    throw .invalidDate
                }
                intervals = [(input.period.start, input.period.end)]
            case .timeline:
                var boundaries = Set([input.period.start, input.period.end])
                for snapshot in input.ownership.snapshots
                    where snapshot.start > input.period.start && snapshot.start < input.period.end {
                    boundaries.insert(snapshot.start)
                }
                let ordered = boundaries.sorted()
                intervals = (0..<(ordered.count - 1)).map {
                    (ordered[$0], ordered[$0 + 1])
                }
            }

            var incomeByInterval = [Decimal](
                repeating: .zero, count: intervals.count
            )
            var sourcesByInterval = [[Posting.Source]](
                repeating: [], count: intervals.count
            )
            for posting in incomePostings {
                var lower = 0
                var upper = intervals.count
                while lower < upper {
                    let middle = lower + (upper - lower) / 2
                    if posting.date >= intervals[middle].end {
                        lower = middle + 1
                    } else {
                        upper = middle
                    }
                }
                guard lower < intervals.count,
                      posting.date >= intervals[lower].start else {
                    throw .unassignedIncomePosting(posting.source.entryID)
                }
                incomeByInterval[lower] -= posting.signedAmount
                sourcesByInterval[lower].append(posting.source)
            }

            var segments: [Segment] = []
            var totals: [Entity.Reference: Decimal] = [:]
            for (index, interval) in intervals.enumerated() {
                let date: Date
                switch input.policy.basis {
                case .snapshot(let reference):
                    date = reference
                case .timeline:
                    date = interval.start
                }
                guard let snapshot = input.ownership.snapshot(at: date) else {
                    throw .missingShares(date)
                }
                let selected: [Entity.Reference: Decimal]
                switch input.policy.attribution {
                case .declared:
                    selected = snapshot.declared
                case .effective:
                    selected = snapshot.effective
                }
                let active = selected.filter { $0.value > 0 }.sorted {
                    $0.key.identifier < $1.key.identifier
                }
                guard !active.isEmpty else {
                    throw .missingShares(date)
                }

                var shares: [Entity.Reference: Decimal] = [:]
                var allocated: [Entity.Reference: Decimal] = [:]
                var running = Decimal.zero
                let amount = incomeByInterval[index]
                for (position, item) in active.enumerated() {
                    shares[item.key] = item.value
                    // Conserve signed income exactly; keep any fractional
                    // Decimal residual with the final deterministic owner.
                    let part = position == active.count - 1
                        ? amount - running
                        : amount * item.value
                    allocated[item.key] = part
                    totals[item.key, default: 0] += part
                    running += part
                }
                segments.append(Segment(
                    start: interval.start,
                    end: interval.end,
                    netIncome: amount,
                    shares: shares,
                    declared: snapshot.declared,
                    effective: snapshot.effective,
                    amounts: allocated,
                    sources: sourcesByInterval[index]
                ))
            }

            return Result(
                period: input.period,
                ownership: input.ownership,
                attribution: input.policy.attribution,
                decision: .derived(input.policy.basis),
                netIncome: netIncome,
                amounts: totals,
                segments: segments,
                posted: posted,
                postedDifference: postedDifference
            )
        }
    }
}
