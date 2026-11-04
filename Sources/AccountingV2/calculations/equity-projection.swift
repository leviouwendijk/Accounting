import Foundation

public extension Equity {
    /// A temporal projection of accepted owner capital, recorded movements,
    /// and a single profit-allocation decision. No journal entries are created.
    struct Projection: Calculation {
        public struct Input: Sendable {
            public let rollforward: Rollforward.Result

            public init(rollforward: Rollforward.Result) {
                self.rollforward = rollforward
            }
        }

        public enum Error: Swift.Error, Equatable, Sendable {
            case snapshotProfitHasNoTemporalAttribution
            case inconsistentProfitSegments
            case unknownSource(Posting.Source)
            case inconsistentRollforward(Entity.Reference)
            case nonconservingClosing(Decimal)
        }

        public struct Segment: Sendable {
            public let start: Date
            public let end: Date
            /// Includes allocated profit, which may be derived, not posted.
            public let directOpening: [Entity.Reference: Decimal]
            public let effectiveOpening: [Entity.Reference: Decimal]
            public let contributions: [Entity.Reference: Decimal]
            public let drawings: [Entity.Reference: Decimal]
            public let profit: [Entity.Reference: Decimal]
            public let directClosing: [Entity.Reference: Decimal]
            public let effectiveClosing: [Entity.Reference: Decimal]
            /// Reattribution at this ownership boundary, never a journal movement.
            public let transitionAdjustments: [Entity.Reference: Decimal]
            /// Effective less direct at the end of this interval.
            public let closingAdjustments: [Entity.Reference: Decimal]
            public let movements: [Rollforward.Movement]
            public let profitSources: [Posting.Source]
        }

        /// Equity-only components at the reporting boundary.
        /// Not a journal position, closing entry, or Equity.Anchor.
        /// Recorded capital retains its original entity, while profit
        /// already attributed effectively must not be distributed again.
        public struct ClosingState: Sendable {
            public let periodStart: Date
            public let boundary: Date
            public let chart: Chart
            public let entities: Entities
            public let openingStateIdentifier: Provenance.Identifier
            /// Exact canonical source history through the closing boundary.
            public let sourceHistory: Journal.History
            public let recordedCapital: [Entity.Reference: Decimal]
            /// Profit assigned under the original allocation decision.
            public let allocatedProfit: [Entity.Reference: Decimal]
            /// Profit resolved to beneficiaries when earned.
            public let effectiveProfit: [Entity.Reference: Decimal]

            public var recordedCapitalTotal: Decimal {
                recordedCapital.values.reduce(Decimal.zero, +)
            }

            public var allocatedProfitTotal: Decimal {
                allocatedProfit.values.reduce(Decimal.zero, +)
            }

            public var effectiveProfitTotal: Decimal {
                effectiveProfit.values.reduce(Decimal.zero, +)
            }

            public var directTotal: Decimal {
                recordedCapitalTotal + allocatedProfitTotal
            }

            public var effectiveTotal: Decimal {
                recordedCapitalTotal + effectiveProfitTotal
            }

            internal init(
                periodStart: Date,
                boundary: Date,
                chart: Chart,
                entities: Entities,
                openingStateIdentifier: Provenance.Identifier,
                sourceHistory: Journal.History,
                recordedCapital: [Entity.Reference: Decimal],
                allocatedProfit: [Entity.Reference: Decimal],
                effectiveProfit: [Entity.Reference: Decimal]
            ) {
                self.periodStart = periodStart
                self.boundary = boundary
                self.chart = chart
                self.entities = entities
                self.openingStateIdentifier = openingStateIdentifier
                self.sourceHistory = sourceHistory
                self.recordedCapital = recordedCapital
                self.allocatedProfit = allocatedProfit
                self.effectiveProfit = effectiveProfit
            }
        }

        public struct Result: Sendable {
            public let closingState: ClosingState
            public let rollforward: Rollforward.Result
            public let segments: [Segment]
            public let directClosing: [Entity.Reference: Decimal]
            public let effectiveClosing: [Entity.Reference: Decimal]
            public let adjustments: [Entity.Reference: Decimal]

            public var directTotal: Decimal {
                directClosing.values.reduce(Decimal.zero, +)
            }

            public var effectiveTotal: Decimal {
                effectiveClosing.values.reduce(Decimal.zero, +)
            }

            public var adjustmentTotal: Decimal {
                adjustments.values.reduce(Decimal.zero, +)
            }
        }

        public init() {}

        public func evaluate(_ input: Input) throws -> Result {
            let rollforward = input.rollforward
            let allocation = rollforward.allocation
            let period = allocation.period
            let structure = allocation.ownership

            if case .derived(.snapshot) = allocation.decision {
                throw Error.snapshotProfitHasNoTemporalAttribution
            }

            var boundaries = Set([period.start, period.end])
            for snapshot in structure.snapshots
                where snapshot.start > period.start && snapshot.start < period.end {
                boundaries.insert(snapshot.start)
            }
            let ordered = boundaries.sorted()
            let windows = zip(ordered, ordered.dropFirst()).map { ($0, $1) }

            if case .derived(.timeline) = allocation.decision {
                guard allocation.segments.count == windows.count else {
                    throw Error.inconsistentProfitSegments
                }
                for (index, window) in windows.enumerated() {
                    guard allocation.segments[index].start == window.0,
                          allocation.segments[index].end == window.1 else {
                        throw Error.inconsistentProfitSegments
                    }
                }
            }

            let dates = Dictionary(uniqueKeysWithValues:
                period.movements.postings.map { ($0.source, $0.date) }
            )

            func add(
                _ target: inout [Entity.Reference: Decimal],
                _ delta: [Entity.Reference: Decimal]
            ) {
                for (owner, amount) in delta {
                    target[owner, default: 0] += amount
                }
            }

            func combined(
                _ first: [Entity.Reference: Decimal],
                _ second: [Entity.Reference: Decimal]
            ) -> [Entity.Reference: Decimal] {
                var result = first
                add(&result, second)
                return result
            }

            func difference(
                _ effective: [Entity.Reference: Decimal],
                _ direct: [Entity.Reference: Decimal]
            ) -> [Entity.Reference: Decimal] {
                var result: [Entity.Reference: Decimal] = [:]
                for owner in Set(effective.keys).union(direct.keys) {
                    let delta = (effective[owner] ?? 0) - (direct[owner] ?? 0)
                    if delta != 0 { result[owner] = delta }
                }
                return result
            }

            func activeAmounts(
                _ values: [Entity.Reference: Decimal]
            ) -> [Entity.Reference: Decimal] {
                values.filter { $0.value != 0 }
            }

            // Journal-derived capital is resolved as of each boundary.
            // Profit already attributed effectively is carried separately.
            var capital = rollforward.anchor.amounts
            var directProfit: [Entity.Reference: Decimal] = [:]
            var effectiveProfit: [Entity.Reference: Decimal] = [:]
            var previousEffectiveClosing: [Entity.Reference: Decimal]?
            var segments: [Segment] = []

            for (index, window) in windows.enumerated() {
                let (start, end) = window
                let effectiveCapitalOpening = try structure.distribute(
                    activeAmounts(capital), at: start
                ).effective
                let directOpening = combined(capital, directProfit)
                let effectiveOpening = combined(effectiveCapitalOpening, effectiveProfit)
                let transition = previousEffectiveClosing.map {
                    difference(effectiveOpening, $0)
                } ?? [:]

                var segmentContributions: [Entity.Reference: Decimal] = [:]
                var segmentDrawings: [Entity.Reference: Decimal] = [:]
                var sourceMovements: [Rollforward.Movement] = []
                for movement in rollforward.movements {
                    guard let date = dates[movement.source] else {
                        throw Error.unknownSource(movement.source)
                    }
                    guard date >= start && date < end else { continue }
                    sourceMovements.append(movement)
                    switch movement.kind {
                    case .contribution:
                        capital[movement.owner, default: 0] += movement.amount
                        segmentContributions[movement.owner, default: 0] += movement.amount
                    case .drawing:
                        capital[movement.owner, default: 0] -= movement.amount
                        segmentDrawings[movement.owner, default: 0] += movement.amount
                    }
                }

                var profit: [Entity.Reference: Decimal] = [:]
                var sources: [Posting.Source] = []
                switch allocation.decision {
                case .derived(.timeline):
                    let source = allocation.segments[index]
                    profit = source.amounts
                    sources = source.sources
                case .posted:
                    for item in allocation.posted {
                        guard let date = dates[item.source] else {
                            throw Error.unknownSource(item.source)
                        }
                        guard date >= start && date < end else { continue }
                        profit[item.owner, default: 0] += item.amount
                        sources.append(item.source)
                    }
                case .derived(.snapshot):
                    throw Error.snapshotProfitHasNoTemporalAttribution
                }
                add(&directProfit, profit)

                switch allocation.decision {
                case .derived(.timeline):
                    switch allocation.attribution {
                    case .effective:
                        add(&effectiveProfit, profit)
                    case .declared:
                        add(&effectiveProfit, try structure.distribute(
                            activeAmounts(profit), at: start
                        ).effective)
                    case nil:
                        throw Error.inconsistentProfitSegments
                    }
                case .posted:
                    add(&effectiveProfit, try structure.distribute(
                        activeAmounts(profit), at: start
                    ).effective)
                case .derived(.snapshot):
                    throw Error.snapshotProfitHasNoTemporalAttribution
                }

                let directClosing = combined(capital, directProfit)
                let effectiveCapitalClosing = try structure.distribute(
                    activeAmounts(capital), at: start
                ).effective
                let effectiveClosing = combined(effectiveCapitalClosing, effectiveProfit)
                let adjustments = difference(effectiveClosing, directClosing)
                segments.append(Segment(
                    start: start,
                    end: end,
                    directOpening: directOpening,
                    effectiveOpening: effectiveOpening,
                    contributions: segmentContributions,
                    drawings: segmentDrawings,
                    profit: profit,
                    directClosing: directClosing,
                    effectiveClosing: effectiveClosing,
                    transitionAdjustments: transition,
                    closingAdjustments: adjustments,
                    movements: sourceMovements,
                    profitSources: sources
                ))
                previousEffectiveClosing = effectiveClosing
            }

            guard let last = segments.last else {
                throw Error.inconsistentProfitSegments
            }
            for (owner, position) in rollforward.positions {
                guard (last.directClosing[owner] ?? 0) == position.closing else {
                    throw Error.inconsistentRollforward(owner)
                }
            }
            let total = last.directClosing.values.reduce(Decimal.zero, +)
            guard total == rollforward.closing else {
                throw Error.nonconservingClosing(total - rollforward.closing)
            }
            let effectiveTotal = last.effectiveClosing.values.reduce(Decimal.zero, +)
            guard effectiveTotal == total else {
                throw Error.nonconservingClosing(effectiveTotal - total)
            }
            return Result(
                closingState: ClosingState(
                    periodStart: period.start,
                    boundary: period.end,
                    chart: period.ledger.journal.chart,
                    entities: period.ledger.journal.entities,
                    openingStateIdentifier: rollforward.anchor.position.provenance.result,
                    sourceHistory: Journal.History(
                        period.ledger.journal, before: period.end
                    ),
                    recordedCapital: capital,
                    allocatedProfit: directProfit,
                    effectiveProfit: effectiveProfit
                ),
                rollforward: rollforward,
                segments: segments,
                directClosing: last.directClosing,
                effectiveClosing: last.effectiveClosing,
                adjustments: last.closingAdjustments
            )
        }
    }
}
