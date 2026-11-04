import Foundation

public extension Equity {
    /// Advances a validated equity opening using only the new period's sources.
    /// Historical effective profit stays with the beneficiary who earned it.
    struct Advancement: Calculation {
        public struct Input: Sendable {
            public let opening: Continuation.Result
            public let contributions: Set<Account.Reference>
            public let drawings: Set<Account.Reference>

            public init(
                opening: Continuation.Result,
                contributions: Set<Account.Reference> = [],
                drawings: Set<Account.Reference> = []
            ) {
                self.opening = opening
                self.contributions = contributions
                self.drawings = drawings
            }
        }

        public enum Error: Swift.Error, Equatable, Sendable {
            case unbalancedAllocation(Decimal)
            case invalidMovement(Rollforward.Error)
            case invalidCapitalRoute(Ownership.Structure.DistributionError)
            case invalidProfitRoute(Ownership.Structure.DistributionError)
            case inconsistentProfitSegments
            case inconsistentProfitAllocation
            case unknownSource(Posting.Source)
            case nonconservingClosing(Decimal)
        }

        public struct Result: Sendable {
            public let opening: Continuation.Result
            public let closingState: Projection.ClosingState
            public let movements: [Rollforward.Movement]
            public let profitSources: [Posting.Source]
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
            let opening = input.opening
            let allocation = opening.allocation
            let period = allocation.period
            let structure = allocation.ownership
            guard allocation.remainder == 0 else {
                throw Error.unbalancedAllocation(allocation.remainder)
            }

            let movements: [Rollforward.Movement]
            do {
                movements = try Rollforward().classifiedMovements(
                    allocation: allocation,
                    contributions: input.contributions,
                    drawings: input.drawings
                )
            } catch {
                throw Error.invalidMovement(error)
            }

            let dates = Dictionary(uniqueKeysWithValues:
                period.movements.postings.map { ($0.source, $0.date) }
            )
            var boundaries = Set([period.start, period.end])
            for snapshot in structure.snapshots
                where snapshot.start > period.start && snapshot.start < period.end {
                boundaries.insert(snapshot.start)
            }
            let ordered = boundaries.sorted()
            let windows = zip(ordered, ordered.dropFirst()).map { ($0, $1) }
            guard let lastStart = windows.last?.0 else {
                throw Error.inconsistentProfitSegments
            }

            if case .derived(.timeline) = allocation.decision {
                guard allocation.segments.count == windows.count else {
                    throw Error.inconsistentProfitSegments
                }
                for (index, window) in windows.enumerated() {
                    let segment = allocation.segments[index]
                    guard segment.start == window.0 && segment.end == window.1 else {
                        throw Error.inconsistentProfitSegments
                    }
                }
            }

            func add(
                _ amounts: [Entity.Reference: Decimal],
                to target: inout [Entity.Reference: Decimal]
            ) {
                for (owner, amount) in amounts {
                    target[owner, default: 0] += amount
                }
            }

            func joined(
                _ first: [Entity.Reference: Decimal],
                _ second: [Entity.Reference: Decimal]
            ) -> [Entity.Reference: Decimal] {
                var result = first
                add(second, to: &result)
                return result
            }

            func distributed(
                _ capital: [Entity.Reference: Decimal],
                at date: Date
            ) throws -> [Entity.Reference: Decimal] {
                do {
                    return try structure.distribute(
                        capital.filter { $0.value != 0 }, at: date
                    ).effective
                } catch {
                    throw Error.invalidCapitalRoute(error)
                }
            }

            // Validate collapse routes at every effective-date boundary, with
            // capital movements applied only within their own [start, end) window.
            var capital = opening.recordedCapital
            for (start, end) in windows {
                _ = try distributed(capital, at: start)
                for movement in movements {
                    guard let date = dates[movement.source] else {
                        throw Error.unknownSource(movement.source)
                    }
                    guard date >= start && date < end else { continue }
                    switch movement.kind {
                    case .contribution:
                        capital[movement.owner, default: 0] += movement.amount
                    case .drawing:
                        capital[movement.owner, default: 0] -= movement.amount
                    }
                }
                _ = try distributed(capital, at: start)
            }

            // The two historical profit views are carried forward unchanged;
            // only this period's allocation is added to each view.
            var allocatedProfit = opening.allocatedProfit
            var effectiveProfit = opening.effectiveProfit
            var newProfit: [Entity.Reference: Decimal] = [:]
            var profitSources: [Posting.Source] = []
            switch allocation.decision {
            case .derived(.timeline):
                guard let attribution = allocation.attribution else {
                    throw Error.inconsistentProfitSegments
                }
                for segment in allocation.segments {
                    add(segment.amounts, to: &allocatedProfit)
                    add(segment.amounts, to: &newProfit)
                    profitSources.append(contentsOf: segment.sources)
                    switch attribution {
                    case .effective:
                        add(segment.amounts, to: &effectiveProfit)
                    case .declared:
                        do {
                            let resolved = try structure.distribute(
                                segment.amounts.filter { $0.value != 0 },
                                at: segment.start
                            ).effective
                            add(resolved, to: &effectiveProfit)
                        } catch {
                            throw Error.invalidProfitRoute(error)
                        }
                    }
                }
            case .posted:
                for posting in allocation.posted {
                    guard let date = dates[posting.source] else {
                        throw Error.unknownSource(posting.source)
                    }
                    let amount = [posting.owner: posting.amount]
                    add(amount, to: &allocatedProfit)
                    add(amount, to: &newProfit)
                    profitSources.append(posting.source)
                    do {
                        let resolved = try structure.distribute(amount, at: date).effective
                        add(resolved, to: &effectiveProfit)
                    } catch {
                        throw Error.invalidProfitRoute(error)
                    }
                }
            case .derived(.snapshot):
                throw Error.inconsistentProfitSegments
            }

            for owner in Set(newProfit.keys).union(allocation.amounts.keys) {
                guard (newProfit[owner] ?? 0) == (allocation.amounts[owner] ?? 0) else {
                    throw Error.inconsistentProfitAllocation
                }
            }
            let effectiveCapital = try distributed(capital, at: lastStart)
            let direct = joined(capital, allocatedProfit)
            let effective = joined(effectiveCapital, effectiveProfit)
            var capitalDelta = Decimal.zero
            for movement in movements {
                switch movement.kind {
                case .contribution:
                    capitalDelta += movement.amount
                case .drawing:
                    capitalDelta -= movement.amount
                }
            }
            let expected = opening.directTotal + allocation.netIncome + capitalDelta
            let directTotal = direct.values.reduce(Decimal.zero, +)
            let effectiveTotal = effective.values.reduce(Decimal.zero, +)
            guard directTotal == expected && effectiveTotal == expected else {
                throw Error.nonconservingClosing(effectiveTotal - expected)
            }
            var adjustments: [Entity.Reference: Decimal] = [:]
            for owner in Set(direct.keys).union(effective.keys) {
                let delta = (effective[owner] ?? 0) - (direct[owner] ?? 0)
                if delta != 0 { adjustments[owner] = delta }
            }
            let closingState = Projection.ClosingState(
                periodStart: period.start,
                boundary: period.end,
                chart: period.ledger.journal.chart,
                entities: period.ledger.journal.entities,
                openingStateIdentifier: opening.previous.openingStateIdentifier,
                sourceHistory: Journal.History(
                    period.ledger.journal, before: period.end
                ),
                recordedCapital: capital,
                allocatedProfit: allocatedProfit,
                effectiveProfit: effectiveProfit
            )
            return Result(
                opening: opening,
                closingState: closingState,
                movements: movements,
                profitSources: profitSources,
                directClosing: direct,
                effectiveClosing: effective,
                adjustments: adjustments
            )
        }
    }
}
