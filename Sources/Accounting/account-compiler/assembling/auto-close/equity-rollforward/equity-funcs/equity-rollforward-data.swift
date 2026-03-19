import Foundation

public extension RGSPrinter {
    /// Build the same owner-equity history you currently print, but return data models.
    static func buildOwnerEquityRollforwardHistoryData(
        allPeriods: [EquityPeriod],
        chart: CompiledChart,
        entities: EntityStore,
        view: ClosedRange<Int>? = nil,
        config cfg: EquityRollforwardConfig = .init()
    ) throws -> [PeriodRollforward] {
        guard !allPeriods.isEmpty else { return [] }
        let maps = ChartMaps(chart: chart)

        // Compute earliest BEGIN exactly like your printer does:
        var beginByOwner = try buildEarliestBeginMap(
            earliest: allPeriods[0], chart: chart, entities: entities, cfg: cfg, maps: maps
        )

        var result: [PeriodRollforward] = []

        for (i, p) in allPeriods.enumerated() {
            let (moveOwners, deltas, alloc) = try buildOwnerDeltas(
                bundle: p.bundle, chart: chart, entities: entities, asOf: p.asOf, cfg: cfg, maps: maps
            )
            let closeOwners = Set(equityClosingByOwner(bundle: p.bundle, cfg: cfg, maps: maps).keys)
            var owners = Array(Set(moveOwners).union(beginByOwner.keys).union(closeOwners)); owners.sort()

            var endByOwner: [Int: Decimal] = [:]
            for oid in owners {
                let d = deltas[oid] ?? OwnerDelta(stort: 0, onttrek: 0, winst: 0)
                endByOwner[oid] = (beginByOwner[oid] ?? 0) + d.delta
            }

            let (openTotal, closeTotal) = equityPresentationTotals(
                periodIndex: i, periods: allPeriods, chart: chart, cfg: cfg, maps: maps
            )

            result.append(
                PeriodRollforward(
                    owners: owners,
                    beginByOwner: beginByOwner,
                    deltas: deltas,
                    endByOwner: endByOwner,
                    niTotal: alloc.niTotal,
                    winstSource: alloc.source,
                    allocationNote: Dictionary(uniqueKeysWithValues: owners.map { oid in
                        (oid, (alloc.effectivePercents[oid] ?? 0, alloc.usedAmounts[oid] ?? 0))
                    }),
                    openingTotal: openTotal,
                    closingTotal: closeTotal
                )
            )

            beginByOwner = endByOwner
        }

        if let v = view {
            let lo = max(v.lowerBound, 0)
            let hi = min(v.upperBound, result.count - 1)
            return (lo <= hi) ? Array(result[lo...hi]) : []
        }
        return result
    }
}
