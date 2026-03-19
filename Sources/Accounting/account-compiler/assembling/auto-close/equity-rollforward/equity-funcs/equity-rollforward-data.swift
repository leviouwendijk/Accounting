import Foundation

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

public func equityAnchorMessages(
    earliest: EquityPeriod,
    cfg: EquityRollforwardConfig,
    maps: ChartMaps
) -> [String] {
    let hasPostedBegin: Bool = {
        if let eb = earliest.bundle.entity?.byAccount,
           let code = cfg.entity.periodOpeningRouting.equityOpeningCode,
           let id = maps.idByCode[code] {
            return eb[id] != nil
        }
        return false
    }()

    let hasPerOwnerClosing = !equityClosingByOwner(
        bundle: earliest.bundle,
        cfg: cfg,
        maps: maps
    ).isEmpty

    if hasPostedBegin {
        return ["Earliest anchor: owner-tagged opening found — using posted per-owner BEGIN."]
    } else if hasPerOwnerClosing {
        return ["Earliest anchor: backsolved from per-owner closing − movements (no % guessing)."]
    } else {
        return ["Earliest anchor: none posted and no per-owner closing — BEGIN = 0 per owner."]
    }
}

public func buildOwnerEquityRollforwardReport(
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
            anchorMessages: []
        )
    }

    let maps = ChartMaps(chart: chart)
    let earliest = allPeriods[0]
    let anchorMessages = equityAnchorMessages(
        earliest: earliest,
        cfg: cfg,
        maps: maps
    )

    var beginByOwner = try buildEarliestBeginMap(
        earliest: earliest,
        chart: chart,
        entities: entities,
        cfg: cfg,
        maps: maps
    )

    var built: [EquityReportPeriod] = []

    for (i, p) in allPeriods.enumerated() {
        let (moveOwners, deltas, alloc) = try buildOwnerDeltas(
            bundle: p.bundle,
            chart: chart,
            entities: entities,
            asOf: p.asOf,
            cfg: cfg,
            maps: maps
        )

        let closeOwners = Set(
            equityClosingByOwner(bundle: p.bundle, cfg: cfg, maps: maps).keys
        )

        var owners = Array(Set(moveOwners).union(beginByOwner.keys).union(closeOwners))
        owners.sort()

        var endByOwner: [Int: Decimal] = [:]
        for oid in owners {
            let d = deltas[oid] ?? OwnerDelta(stort: 0, onttrek: 0, winst: 0)
            endByOwner[oid] = (beginByOwner[oid] ?? 0) + d.delta
        }

        let (openTotal, closeTotal) = equityPresentationTotals(
            periodIndex: i,
            periods: allPeriods,
            chart: chart,
            cfg: cfg,
            maps: maps
        )

        var note: [Int: (Decimal, Decimal)] = [:]
        for oid in owners {
            let amt = alloc.usedAmounts[oid] ?? 0
            let pct = alloc.usePosted
                ? ((alloc.niTotal == 0) ? 0 : (amt / alloc.niTotal))
                : (alloc.effectivePercents[oid] ?? 0)
            note[oid] = (pct, amt)
        }

        let rows = PeriodRollforward(
            owners: owners,
            beginByOwner: beginByOwner,
            deltas: deltas,
            endByOwner: endByOwner,
            niTotal: alloc.niTotal,
            winstSource: alloc.source,
            allocationNote: note,
            openingTotal: openTotal,
            closingTotal: closeTotal
        )

        if view == nil || view!.contains(i) {
            built.append(
                .init(
                    label: p.label,
                    rows: rows
                )
            )
        }

        beginByOwner = endByOwner
    }

    return .init(
        title: title,
        periods: built,
        anchorMessages: anchorMessages
    )
}

public func buildOwnerEquityRollforwardReportAsync(
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
            anchorMessages: []
        )
    }

    let maps = ChartMaps(chart: chart)
    let anchorMessages = equityAnchorMessages(
        earliest: allPeriods[0],
        cfg: cfg,
        maps: maps
    )

    let solved = try await buildGlobalRollforwardConcurrent(
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

    return .init(
        title: title,
        periods: periods,
        anchorMessages: anchorMessages
    )
}
