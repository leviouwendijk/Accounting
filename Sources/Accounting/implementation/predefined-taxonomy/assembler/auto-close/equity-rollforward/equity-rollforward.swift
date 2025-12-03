import Foundation

/// Print owner equity rollforward using *global* backsolve across `allPeriods`,
/// but only render rows for indices in `view` (e.g. previous+current).
public func runOwnerEquityRollforwardHistory(
    title: String = "IB equity rollforward (owner split, backsolved)",
    allPeriods: [EquityPeriod],
    chart: CompiledChart,
    entities: EntityStore,
    view: ClosedRange<Int>?,                 // nil → print all
    config cfg: EquityRollforwardConfig = .init(),
    afterEachPeriod: ((EquityPeriod, [Int], [Int: OwnerDelta], EquityRollforwardConfig) -> Void)? = nil
) throws {
    guard !allPeriods.isEmpty else { printHeader(title); print("(no periods)"); return }

    let maps = ChartMaps(chart: chart)
    let earliest = allPeriods[0]

    // Announce anchor mode once (same logic you already have)
    let hasPostedBegin: Bool = {
        if let eb = earliest.bundle.entity?.byAccount,
           let code = cfg.entity.periodOpeningRouting.equityOpeningCode,
           let id = maps.idByCode[code] { return eb[id] != nil }
        return false
    }()
    let hasPerOwnerClosing = !equityClosingByOwner(bundle: earliest.bundle, cfg: cfg, maps: maps).isEmpty

    printHeader(title)
    if hasPostedBegin {
        print("Earliest anchor: owner-tagged opening found — using posted per-owner BEGIN.")
    } else if hasPerOwnerClosing {
        print("Earliest anchor: backsolved from per-owner closing − movements (no % guessing).")
    } else {
        print("Earliest anchor: none posted and no per-owner closing — BEGIN = 0 per owner.")
    }

    // Compute earliest BEGIN
    var beginByOwner = try buildEarliestBeginMap(
        earliest: earliest, chart: chart, entities: entities, cfg: cfg, maps: maps
    )

    // Walk *all* periods to keep the math globally correct.
    for (i, p) in allPeriods.enumerated() {
        let (moveOwners, deltas, alloc) = try buildOwnerDeltas(
            bundle: p.bundle, chart: chart, entities: entities, asOf: p.asOf, cfg: cfg, maps: maps
        )
        let closeOwners = Set(equityClosingByOwner(bundle: p.bundle, cfg: cfg, maps: maps).keys)
        var owners = Array(Set(moveOwners).union(beginByOwner.keys).union(closeOwners))
        owners.sort()

        var endByOwner: [Int: Decimal] = [:]
        for oid in owners {
            let d = deltas[oid] ?? OwnerDelta(stort: 0, onttrek: 0, winst: 0)
            endByOwner[oid] = (beginByOwner[oid] ?? 0) + d.delta
        }

        let (openTotal, closeTotal) = equityPresentationTotals(
            periodIndex: i, periods: allPeriods, chart: chart, cfg: cfg, maps: maps
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

        // // Only print when within the requested view window (but always carry forward)
        // if view == nil || view!.contains(i) {
        //     printPeriod(label: p.label, rows: rows, entities: entities, cfg: cfg)
        // }

        // adding hook
        if view == nil || view!.contains(i) {
            printPeriod(label: p.label, rows: rows, entities: entities, cfg: cfg)
            afterEachPeriod?(p, owners, deltas, cfg)
        }

        beginByOwner = endByOwner
    }
}

/// Async variant: uses `buildGlobalRollforwardConcurrent` to compute the
/// global backsolve in parallel, then prints/handles only the requested view.
public func runOwnerEquityRollforwardHistoryAsync(
    title: String = "IB equity rollforward (owner split, backsolved)",
    allPeriods: [EquityPeriod],
    chart: CompiledChart,
    entities: EntityStore,
    view: ClosedRange<Int>?,                 // nil → print all
    config cfg: EquityRollforwardConfig = .init(),
    afterEachPeriod: ((EquityPeriod, [Int], [Int: OwnerDelta], EquityRollforwardConfig) -> Void)? = nil
) async throws {
    guard !allPeriods.isEmpty else {
        printHeader(title)
        print("(no periods)")
        return
    }

    // Header; anchor diagnostics are printed by `buildGlobalRollforwardConcurrent`
    printHeader(title)

    // Compute full global rollforward concurrently over all periods
    let solved = try await buildGlobalRollforwardConcurrent(
        history: allPeriods,
        chart: chart,
        entities: entities,
        cfg: cfg
    )

    // Decide which indices to render
    let indices: [Int]
    if let viewRange = view {
        let clampedLower = max(viewRange.lowerBound, allPeriods.startIndex)
        let clampedUpper = min(viewRange.upperBound, allPeriods.endIndex - 1)
        indices = Array(clampedLower...clampedUpper)
    } else {
        indices = Array(allPeriods.indices)
    }

    // Print only the requested window, but use the globally solved rows
    for i in indices {
        let period = allPeriods[i]
        let rows   = solved[i]

        printPeriod(label: period.label, rows: rows, entities: entities, cfg: cfg)
        afterEachPeriod?(period, rows.owners, rows.deltas, cfg)
    }
}

// public func runOwnerEquityRollforwardIB_Global(
//     title: String = "IB equity rollforward (owner split, backsolved)",
//     history: [EquityPeriod],                  // full chronological history
//     chart: CompiledChart,
//     entities: EntityStore,
//     printWindow: Range<Int>? = nil,           // which solved periods to print (default: all)
//     config cfg: EquityRollforwardConfig = EquityRollforwardConfig()
// ) throws {
//     guard !history.isEmpty else { printHeader(title); print("(no periods)"); return }
//     let solved = try buildGlobalRollforward(history: history, chart: chart, entities: entities, cfg: cfg)

//     printHeader(title)

//     let window = printWindow ?? history.indices
//     for i in window {
//         printPeriod(label: history[i].label, rows: solved[i], entities: entities, cfg: cfg)
//     }
// }

// /// Thin wrapper (keeps your current call pattern working).
// /// If you can provide full history from the call site, prefer `runOwnerEquityRollforwardIB_Global(...)`.
// public func runOwnerEquityRollforwardIB(
//     title: String = "IB equity rollforward (owner split, backsolved)",
//     current cur: StatementBundle,
//     previous prv: StatementBundle?,
//     chart: CompiledChart,
//     entities: EntityStore,
//     asOfCurrent: Date,
//     asOfPrevious: Date?,
//     history: [EquityPeriod]? = nil,           // ← pass full history here if you have it
//     config cfg: EquityRollforwardConfig = EquityRollforwardConfig()
// ) throws {
//     // If caller already built full history, use it
//     if let hist = history, !hist.isEmpty {
//         try runOwnerEquityRollforwardIB_Global(title: title, history: hist, chart: chart, entities: entities, printWindow: nil, config: cfg)
//         return
//     }

//     // Otherwise, fall back to the two-period window (still solved globally over these)
//     var periods: [EquityPeriod] = []
//     if let p = prv, let pd = asOfPrevious { periods.append(.init(label: "Previous", bundle: p, asOf: pd)) }
//     periods.append(.init(label: "Current", bundle: cur, asOf: asOfCurrent))

//     try runOwnerEquityRollforwardIB_Global(title: title, history: periods, chart: chart, entities: entities, printWindow: nil, config: cfg)
// }

