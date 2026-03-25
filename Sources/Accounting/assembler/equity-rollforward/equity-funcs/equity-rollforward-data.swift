import Foundation

extension OwnerEquity.Rollforward {
    public static func report(
        title: String = "IB equity rollforward (owner split, backsolved)",
        allPeriods: [EquityPeriod],
        chart: CompiledChart,
        entities: EntityStore,
        view: ClosedRange<Int>? = nil,
        config cfg: EquityRollforwardConfig = .init()
    ) throws -> EquityRollforwardReport {
        guard !allPeriods.isEmpty else {
            return .init(
                title: title,
                periods: [],
                anchorMessages: [],
                diagnostics: []
            )
        }

        let maps = ChartMaps(chart: chart)

        let anchorMessages = Self.equityAnchorMessages(
            earliest: allPeriods[0],
            cfg: cfg,
            maps: maps
        )

        let solved = try Self.global_rollforward(
            history: allPeriods,
            chart: chart,
            entities: entities,
            cfg: cfg
        )

        let indices: [Int]
        if let viewRange = view {
            let clampedLower = max(viewRange.lowerBound, allPeriods.startIndex)
            let clampedUpper = min(viewRange.upperBound, allPeriods.endIndex - 1)
            indices = Array(clampedLower...clampedUpper)
        } else {
            indices = Array(allPeriods.indices)
        }

        let periods = indices.map { i in
            EquityReportPeriod(
                label: allPeriods[i].label,
                rows: solved[i]
            )
        }

        var diagnostics: [EquityDiagnostic] = []

        for i in indices {
            let period = allPeriods[i]
            let rows = solved[i]

            if i == 0 {
                diagnostics.append(
                    .ownerMap(
                        kind: .info,
                        periodLabel: period.label,
                        message: "BEGIN map for earliest period",
                        map: rows.beginByOwner
                    )
                )
            }

            let closingByOwner = Self.equityClosingByOwner(
                bundle: period.bundle,
                cfg: cfg,
                maps: maps
            )

            if !closingByOwner.isEmpty {
                let endSum = rows.endByOwner.values.reduce(0, +)
                let closeSum = closingByOwner.values.reduce(0, +)

                if absD(endSum - closeSum) > 0.01 {
                    let diffMap = rows.owners.reduce(into: [Int: Decimal]()) { acc, oid in
                        acc[oid] = (rows.endByOwner[oid] ?? 0) - (closingByOwner[oid] ?? 0)
                    }

                    diagnostics.append(
                        .init(
                            kind: .warning,
                            periodLabel: period.label,
                            message: "Per-owner END sum \(fmtDec(endSum)) != AE closing \(fmtDec(closeSum)); delta = \(fmtDec(endSum - closeSum))"
                        )
                    )

                    diagnostics.append(
                        .ownerMap(
                            kind: .warning,
                            periodLabel: period.label,
                            message: "Per-owner (END − CLOSING)",
                            map: diffMap
                        )
                    )
                }
            }
        }

        return .init(
            title: title,
            periods: periods,
            anchorMessages: anchorMessages,
            diagnostics: diagnostics
        )
    }

    public static func report_async(
        title: String = "IB equity rollforward (owner split, backsolved)",
        allPeriods: [EquityPeriod],
        chart: CompiledChart,
        entities: EntityStore,
        view: ClosedRange<Int>? = nil,
        config cfg: EquityRollforwardConfig = .init()
    ) async throws -> EquityRollforwardReport {
        guard !allPeriods.isEmpty else {
            return .init(
                title: title,
                periods: [],
                anchorMessages: [],
                diagnostics: []
            )
        }

        let maps = ChartMaps(chart: chart)

        let anchorMessages = Self.equityAnchorMessages(
            earliest: allPeriods[0],
            cfg: cfg,
            maps: maps
        )

        let solved = try await Self.global_rollforward_concurrent(
            history: allPeriods,
            chart: chart,
            entities: entities,
            cfg: cfg
        )

        let indices: [Int]
        if let viewRange = view {
            let clampedLower = max(viewRange.lowerBound, allPeriods.startIndex)
            let clampedUpper = min(viewRange.upperBound, allPeriods.endIndex - 1)
            indices = Array(clampedLower...clampedUpper)
        } else {
            indices = Array(allPeriods.indices)
        }

        let periods = indices.map { i in
            EquityReportPeriod(
                label: allPeriods[i].label,
                rows: solved[i]
            )
        }

        var diagnostics: [EquityDiagnostic] = []

        for i in indices {
            let period = allPeriods[i]
            let rows = solved[i]

            if i == 0 {
                diagnostics.append(
                    .ownerMap(
                        kind: .info,
                        periodLabel: period.label,
                        message: "BEGIN map for earliest period",
                        map: rows.beginByOwner
                    )
                )
            }

            let closingByOwner = Self.equityClosingByOwner(
                bundle: period.bundle,
                cfg: cfg,
                maps: maps
            )

            if !closingByOwner.isEmpty {
                let endSum = rows.endByOwner.values.reduce(0, +)
                let closeSum = closingByOwner.values.reduce(0, +)

                if absD(endSum - closeSum) > 0.01 {
                    let diffMap = rows.owners.reduce(into: [Int: Decimal]()) { acc, oid in
                        acc[oid] = (rows.endByOwner[oid] ?? 0) - (closingByOwner[oid] ?? 0)
                    }

                    diagnostics.append(
                        .init(
                            kind: .warning,
                            periodLabel: period.label,
                            message: "Per-owner END sum \(fmtDec(endSum)) != AE closing \(fmtDec(closeSum)); delta = \(fmtDec(endSum - closeSum))"
                        )
                    )

                    diagnostics.append(
                        .ownerMap(
                            kind: .warning,
                            periodLabel: period.label,
                            message: "Per-owner (END − CLOSING)",
                            map: diffMap
                        )
                    )
                }
            }
        }

        return .init(
            title: title,
            periods: periods,
            anchorMessages: anchorMessages,
            diagnostics: diagnostics
        )
    }
}

// REFACTOR IN PROGRESS:
// public extension RGSPrinter {
//     /// Build the same owner-equity history you currently print, but return data models.
//     static func buildOwnerEquityRollforwardHistoryData(
//         allPeriods: [EquityPeriod],
//         chart: CompiledChart,
//         entities: EntityStore,
//         view: ClosedRange<Int>? = nil,
//         config cfg: EquityRollforwardConfig = .init()
//     ) throws -> [PeriodRollforward] {
//         guard !allPeriods.isEmpty else { return [] }
//         let maps = ChartMaps(chart: chart)

//         // Compute earliest BEGIN exactly like your printer does:
//         var beginByOwner = try buildEarliestBeginMap(
//             earliest: allPeriods[0], chart: chart, entities: entities, cfg: cfg, maps: maps
//         )

//         var result: [PeriodRollforward] = []

//         for (i, p) in allPeriods.enumerated() {
//             let (moveOwners, deltas, alloc) = try buildOwnerDeltas(
//                 bundle: p.bundle, chart: chart, entities: entities, asOf: p.asOf, cfg: cfg, maps: maps
//             )
//             let closeOwners = Set(equityClosingByOwner(bundle: p.bundle, cfg: cfg, maps: maps).keys)
//             var owners = Array(Set(moveOwners).union(beginByOwner.keys).union(closeOwners)); owners.sort()

//             var endByOwner: [Int: Decimal] = [:]
//             for oid in owners {
//                 let d = deltas[oid] ?? OwnerDelta(stort: 0, onttrek: 0, winst: 0)
//                 endByOwner[oid] = (beginByOwner[oid] ?? 0) + d.delta
//             }

//             let (openTotal, closeTotal) = equityPresentationTotals(
//                 periodIndex: i, periods: allPeriods, chart: chart, cfg: cfg, maps: maps
//             )

//             result.append(
//                 PeriodRollforward(
//                     owners: owners,
//                     beginByOwner: beginByOwner,
//                     deltas: deltas,
//                     endByOwner: endByOwner,
//                     niTotal: alloc.niTotal,
//                     winstSource: alloc.source,
//                     allocationNote: Dictionary(uniqueKeysWithValues: owners.map { oid in
//                         (oid, (alloc.effectivePercents[oid] ?? 0, alloc.usedAmounts[oid] ?? 0))
//                     }),
//                     openingTotal: openTotal,
//                     closingTotal: closeTotal
//                 )
//             )

//             beginByOwner = endByOwner
//         }

//         if let v = view {
//             let lo = max(v.lowerBound, 0)
//             let hi = min(v.upperBound, result.count - 1)
//             return (lo <= hi) ? Array(result[lo...hi]) : []
//         }
//         return result
//     }
// }
