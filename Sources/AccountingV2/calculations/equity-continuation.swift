import Foundation

public extension Equity {
    /// Validates the equity-only handoff between adjacent reporting periods.
    /// This is not a PositionState, a journal posting, or a new profit decision.
    struct Continuation: Calculation {
        public struct Input: Sendable {
            public let previous: Projection.ClosingState
            public let allocation: Ownership.Allocation.Result

            public init(
                previous: Projection.ClosingState,
                allocation: Ownership.Allocation.Result
            ) {
                self.previous = previous
                self.allocation = allocation
            }
        }

        public enum Error: Swift.Error, Equatable, Sendable {
            case boundaryMismatch
            case incompatibleChart
            case incompatibleEntities
            case incompatibleHistoricalJournal
            case invalidProfitBasis
            case inconsistentPreviousProfit(Decimal)
            case invalidCapitalRoute(Ownership.Structure.DistributionError)
            case nonconservingOpening(Decimal)
        }

        /// Original capital and earned profit remain independently inspectable.
        /// Only original capital is resolved through the new boundary's routes.
        public struct Result: Sendable {
            public let previous: Projection.ClosingState
            public let allocation: Ownership.Allocation.Result
            public let recordedCapital: [Entity.Reference: Decimal]
            public let allocatedProfit: [Entity.Reference: Decimal]
            public let effectiveProfit: [Entity.Reference: Decimal]
            public let directOpening: [Entity.Reference: Decimal]
            public let effectiveOpening: [Entity.Reference: Decimal]
            /// Effective less direct; never a journal mutation.
            public let openingAdjustments: [Entity.Reference: Decimal]

            public var directTotal: Decimal {
                directOpening.values.reduce(Decimal.zero, +)
            }

            public var effectiveTotal: Decimal {
                effectiveOpening.values.reduce(Decimal.zero, +)
            }

            public var adjustmentTotal: Decimal {
                openingAdjustments.values.reduce(Decimal.zero, +)
            }
        }

        public init() {}

        public func evaluate(_ input: Input) throws -> Result {
            let previous = input.previous
            let allocation = input.allocation
            let period = allocation.period
            let journal = period.ledger.journal

            guard previous.boundary == period.start else {
                throw Error.boundaryMismatch
            }
            guard previous.sourceHistory == Journal.History(
                journal, before: period.start
            ) else {
                throw Error.incompatibleHistoricalJournal
            }
            guard previous.chart.isCompatibleForContinuity(with: journal.chart) else {
                throw Error.incompatibleChart
            }
            guard previous.entities.count == journal.entities.count else {
                throw Error.incompatibleEntities
            }
            for entity in previous.entities.all {
                guard let current = journal.entities.entity(entity.reference),
                      current.displayName == entity.displayName,
                      current.details == entity.details,
                      current.metadata == entity.metadata else {
                    throw Error.incompatibleEntities
                }
            }
            if case .derived(.snapshot) = allocation.decision {
                throw Error.invalidProfitBasis
            }
            let profitDifference = previous.allocatedProfitTotal - previous.effectiveProfitTotal
            guard profitDifference == 0 else {
                throw Error.inconsistentPreviousProfit(profitDifference)
            }

            let distribution: Ownership.Structure.Distribution
            do {
                distribution = try allocation.ownership.distribute(
                    previous.recordedCapital.filter { $0.value != 0 },
                    at: period.start
                )
            } catch {
                throw Error.invalidCapitalRoute(error)
            }

            var direct = previous.recordedCapital
            for (owner, amount) in previous.allocatedProfit {
                direct[owner, default: 0] += amount
            }
            var effective = distribution.effective
            for (owner, amount) in previous.effectiveProfit {
                effective[owner, default: 0] += amount
            }
            let directTotal = direct.values.reduce(Decimal.zero, +)
            let effectiveTotal = effective.values.reduce(Decimal.zero, +)
            guard directTotal == previous.directTotal,
                  effectiveTotal == previous.effectiveTotal,
                  directTotal == effectiveTotal else {
                throw Error.nonconservingOpening(effectiveTotal - directTotal)
            }

            var adjustments: [Entity.Reference: Decimal] = [:]
            for owner in Set(direct.keys).union(effective.keys) {
                let delta = (effective[owner] ?? 0) - (direct[owner] ?? 0)
                if delta != 0 {
                    adjustments[owner] = delta
                }
            }
            return Result(
                previous: previous,
                allocation: allocation,
                recordedCapital: previous.recordedCapital,
                allocatedProfit: previous.allocatedProfit,
                effectiveProfit: previous.effectiveProfit,
                directOpening: direct,
                effectiveOpening: effective,
                openingAdjustments: adjustments
            )
        }
    }
}
