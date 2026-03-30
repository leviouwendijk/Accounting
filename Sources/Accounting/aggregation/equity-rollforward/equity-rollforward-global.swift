import Foundation

// CONCURRENT VERSION
internal struct EquityPeriodPieces: Sendable {
    let moveOwners: [Int]
    let deltas: [Int: OwnerDelta]
    let alloc: ProfitAllocation
    let closingByOwner: [Int: Decimal]
    let openingTotal: Decimal
    let closingTotal: Decimal
}

extension OwnerEquity.Rollforward {
    // public func buildGlobalRollforward(
    public static func global_rollforward(
        history: [EquityPeriod],           // FULL chronological history you want to solve
        chart: CompiledChart,
        entities: EntityStore,
        cfg: EquityRollforwardConfig
    ) throws -> [PeriodRollforward] {
        precondition(!history.isEmpty, "history must not be empty")

        let maps = ChartMaps(chart: chart)

        // // Explain anchor choice
        // let earliest = history[0]
        // let hasPostedBegin: Bool = {
        //     if let eb = earliest.bundle.entity?.byAccount,
        //        let code = cfg.entity.periodOpeningRouting.equityOpeningCode,
        //        let id = maps.idByCode[code] { return eb[id] != nil }
        //     return false
        // }()
        // let hasPerOwnerClosing = !equityClosingByOwner(bundle: earliest.bundle, cfg: cfg, maps: maps).isEmpty

        // if hasPostedBegin {
        //     print("Earliest anchor: owner-tagged opening found — using posted per-owner BEGIN.")
        // } else if hasPerOwnerClosing {
        //     print("Earliest anchor: backsolved from per-owner closing − movements (no % guessing).")
        // } else {
        //     print("Earliest anchor: none posted and no per-owner closing — BEGIN = 0 per owner.")
        // }

        // // Earliest BEGIN per owner
        // var beginByOwner = try buildEarliestBeginMap(earliest: earliest, chart: chart, entities: entities, cfg: cfg, maps: maps)
        // rfDumpOwnerMap("BEGIN map for earliest period", map: beginByOwner, entities: entities)

        // simplified:
        let earliest = history[0]

        var beginByOwner = try buildEarliestBeginMap(
            earliest: earliest,
            chart: chart,
            entities: entities,
            cfg: cfg,
            maps: maps
        )

        var out: [PeriodRollforward] = []
        out.reserveCapacity(history.count)

        // Forward pass across the entire history
        for i in history.indices {
            let p = history[i]
            let (moveOwners, deltas, alloc) = try buildOwnerDeltas(bundle: p.bundle, chart: chart, entities: entities, asOf: p.asOf, cfg: cfg, maps: maps)
            let closeOwners = Set(equityClosingByOwner(bundle: p.bundle, cfg: cfg, maps: maps).keys)
            var owners = Array(Set(moveOwners).union(beginByOwner.keys).union(closeOwners))
            owners.sort()

            // Compute per-owner END and carry forward
            var endByOwner: [Int: Decimal] = [:]
            for oid in owners {
                let d = deltas[oid] ?? OwnerDelta(stort: 0, onttrek: 0, winst: 0)
                endByOwner[oid] = (beginByOwner[oid] ?? 0) + d.delta
            }

            // Presentation totals (display only)
            let (openTotal, closeTotal) = equityPresentationTotals(periodIndex: i, periods: history, chart: chart, cfg: cfg, maps: maps)

            // Allocation note
            var note: [Int: (Decimal, Decimal)] = [:]
            for oid in owners {
                let amt = alloc.usedAmounts[oid] ?? 0
                let pct = alloc.usePosted
                    ? ((alloc.niTotal == 0) ? 0 : (amt / alloc.niTotal))
                    : (alloc.effectivePercents[oid] ?? 0)
                note[oid] = (pct, amt)
            }

            // Pack a row
            let row = PeriodRollforward(
                asOf: p.asOf,
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
            out.append(row)

            // // Debug reconciliation against AE closing for this period
            // let perOwnerClose = equityClosingByOwner(bundle: p.bundle, cfg: cfg, maps: maps)
            // if !perOwnerClose.isEmpty {
            //     let endSum = endByOwner.values.reduce(0, +)
            //     let closeSum = perOwnerClose.values.reduce(0, +)
            //     if absD(endSum - closeSum) > 0.01 {
            //         rfDbg("[\(p.label)] WARNING: per-owner END sum \(fmtDec(endSum)) ≠ AE closing \(fmtDec(closeSum)); Δ=\(fmtDec(endSum - closeSum))")
            //         rfDumpOwnerMap("[\(p.label)] per-owner (END − CLOSING)", map: owners.reduce(into: [Int:Decimal]()) { acc, oid in acc[oid] = (endByOwner[oid] ?? 0) - (perOwnerClose[oid] ?? 0) })
            //     }
            // }

            // Carry forward to next period
            beginByOwner = endByOwner
        }

        return out
    }

    // public func buildGlobalRollforwardConcurrent(
    public static func global_rollforward_concurrent(
        history: [EquityPeriod],
        chart: CompiledChart,
        entities: EntityStore,
        cfg: EquityRollforwardConfig
    ) async throws -> [PeriodRollforward] {
        precondition(!history.isEmpty, "history must not be empty")

        let maps = ChartMaps(chart: chart)
        // let earliest = history[0]

        // // Same anchor diagnostics as the sync version
        // let hasPostedBegin: Bool = {
        //     if let eb = earliest.bundle.entity?.byAccount,
        //        let code = cfg.entity.periodOpeningRouting.equityOpeningCode,
        //        let id = maps.idByCode[code] { return eb[id] != nil }
        //     return false
        // }()
        // let hasPerOwnerClosing = !equityClosingByOwner(bundle: earliest.bundle, cfg: cfg, maps: maps).isEmpty

        // if hasPostedBegin {
        //     print("Earliest anchor: owner-tagged opening found — using posted per-owner BEGIN.")
        // } else if hasPerOwnerClosing {
        //     print("Earliest anchor: backsolved from per-owner closing − movements (no % guessing).")
        // } else {
        //     print("Earliest anchor: none posted and no per-owner closing — BEGIN = 0 per owner.")
        // }

        // // Earliest BEGIN per owner (same helper as sync version)
        // var beginByOwner = try buildEarliestBeginMap(
        //     earliest: earliest,
        //     chart: chart,
        //     entities: entities,
        //     cfg: cfg,
        //     maps: maps
        // )
        // rfDumpOwnerMap("BEGIN map for earliest period", map: beginByOwner, entities: entities)

        // simplified:
        let earliest = history[0]

        var beginByOwner = try buildEarliestBeginMap(
            earliest: earliest,
            chart: chart,
            entities: entities,
            cfg: cfg,
            maps: maps
        )

        // 1) Precompute heavy per-period pieces in parallel
        var pieces = Array<EquityPeriodPieces?>(repeating: nil, count: history.count)

        try await withThrowingTaskGroup(of: (Int, EquityPeriodPieces).self) { group in
            for i in history.indices {
                let period = history[i]
                group.addTask { [i, period, chart, entities, cfg, maps] in
                    let (moveOwners, deltas, alloc) = try buildOwnerDeltas(
                        bundle: period.bundle,
                        chart: chart,
                        entities: entities,
                        asOf: period.asOf,
                        cfg: cfg,
                        maps: maps
                    )

                    let closingByOwner = equityClosingByOwner(
                        bundle: period.bundle,
                        cfg: cfg,
                        maps: maps
                    )

                    let (openTotal, closeTotal) = equityPresentationTotals(
                        periodIndex: i,
                        // periods: [period],   // or pass history + i if that function really needs the whole array
                        periods: history,   // or pass history + i if that function really needs the whole array
                        chart: chart,
                        cfg: cfg,
                        maps: maps
                    )

                    let piece = EquityPeriodPieces(
                        moveOwners: moveOwners,
                        deltas: deltas,
                        alloc: alloc,
                        closingByOwner: closingByOwner,
                        openingTotal: openTotal,
                        closingTotal: closeTotal
                    )
                    return (i, piece)
                }
            }

            for try await (i, piece) in group {
                pieces[i] = piece
            }
        }

        // 2) Sequential forward pass: carry BEGIN → END (math identical to sync)
        var out: [PeriodRollforward] = []
        out.reserveCapacity(history.count)

        for i in history.indices {
            guard let piece = pieces[i] else {
                fatalError("Missing precomputed equity period piece for index \(i)")
            }

            // let p = history[i]

            let moveOwners = piece.moveOwners
            let deltas = piece.deltas
            let alloc = piece.alloc
            let closingByOwner = piece.closingByOwner

            let closeOwners = Set(closingByOwner.keys)
            var owners = Array(Set(moveOwners).union(beginByOwner.keys).union(closeOwners))
            owners.sort()

            // END = BEGIN + Δ per owner
            var endByOwner: [Int: Decimal] = [:]
            for oid in owners {
                let d = deltas[oid] ?? OwnerDelta(stort: 0, onttrek: 0, winst: 0)
                endByOwner[oid] = (beginByOwner[oid] ?? 0) + d.delta
            }

            let openTotal = piece.openingTotal
            let closeTotal = piece.closingTotal

            // Allocation note
            var note: [Int: (Decimal, Decimal)] = [:]
            for oid in owners {
                let amt = alloc.usedAmounts[oid] ?? 0
                let pct = alloc.usePosted
                    ? ((alloc.niTotal == 0) ? 0 : (amt / alloc.niTotal))
                    : (alloc.effectivePercents[oid] ?? 0)
                note[oid] = (pct, amt)
            }

            let row = PeriodRollforward(
                asOf: history[i].asOf,
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

            // // Debug reconciliation vs AE closing (same logic, but uses precomputed closingByOwner)
            // if !closingByOwner.isEmpty {
            //     let endSum = endByOwner.values.reduce(0, +)
            //     let closeSum = closingByOwner.values.reduce(0, +)
            //     if absD(endSum - closeSum) > 0.01 {
            //         rfDbg("[\(p.label)] WARNING: per-owner END sum \(fmtDec(endSum)) ≠ AE closing \(fmtDec(closeSum)); Δ=\(fmtDec(endSum - closeSum))")
            //         rfDumpOwnerMap(
            //             "[\(p.label)] per-owner (END − CLOSING)",
            //             map: owners.reduce(into: [Int: Decimal]()) { acc, oid in
            //                 acc[oid] = (endByOwner[oid] ?? 0) - (closingByOwner[oid] ?? 0)
            //             },
            //             entities: entities
            //         )
            //     }
            // }

            out.append(row)
            beginByOwner = endByOwner
        }

        return out
    }
}
