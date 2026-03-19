import Foundation

public func buildHistoryFromInception(
    entries: [Entry],
    endAsOf: Date,
    kind: PeriodKind,
    calendar: Calendar,
    settings: EntryCompilerSettings,
    assemble: (_ periodStart: Date, _ periodEndExcl: Date) throws -> StatementBundle
) throws -> [EquityPeriod] {
    // Lifetime → single bucket (inception…endAsOf)
    if kind == .lifetime {
        let inception = try earliestAbsoluteDate(entries: entries, settings: settings)
        let start = calendar.startOfDay(for: inception)
        let endExcl = nextPeriodStart(after: periodStart(for: endAsOf, kind: .month, calendar: calendar), // put it in next midnight
                                      kind: .month, calendar: calendar)
        let b = try assemble(start, endExcl)
        return [.init(label: "lifetime", bundle: b, asOf: endAsOf)]
    }

    // Align inception to period boundary
    let inception = try earliestAbsoluteDate(entries: entries, settings: settings)
    var curStart = periodStart(for: inception, kind: kind, calendar: calendar)

    // End: make sure the last period contains endAsOf
    let anchorStartForEnd = periodStart(for: endAsOf, kind: kind, calendar: calendar)
    let hardStop = nextPeriodStart(after: anchorStartForEnd, kind: kind, calendar: calendar)

    var out: [EquityPeriod] = []
    while curStart < hardStop {
        let nextStart = nextPeriodStart(after: curStart, kind: kind, calendar: calendar)
        let endExcl = min(nextStart, hardStop)
        let bundle = try assemble(curStart, endExcl)
        out.append(.init(
            label: labelForPeriodStart(curStart, kind: kind, calendar: calendar),
            bundle: bundle,
            asOf: calendar.date(byAdding: .second, value: -1, to: endExcl) ?? endExcl
        ))
        curStart = nextStart
    }
    return out
}

public func buildHistoryFromInceptionAsync(
    entries: [Entry],
    endAsOf: Date,
    kind: PeriodKind,
    calendar: Calendar,
    settings: EntryCompilerSettings,
    assemble_async: @escaping @Sendable (_ periodStart: Date, _ periodEndExcl: Date) async throws -> StatementBundle
) async throws -> [EquityPeriod] {
    // Lifetime → single bucket (inception…endAsOf)
    if kind == .lifetime {
        let inception = try earliestAbsoluteDate(entries: entries, settings: settings)
        let start = calendar.startOfDay(for: inception)
        let endExcl = nextPeriodStart(
            after: periodStart(for: endAsOf, kind: .month, calendar: calendar),
            kind: .month,
            calendar: calendar
        )
        let b = try await assemble_async(start, endExcl)
        return [.init(label: "lifetime", bundle: b, asOf: endAsOf)]
    }

    // Non-lifetime: walk discrete periods from inception → endAsOf
    let inception = try earliestAbsoluteDate(entries: entries, settings: settings)
    var curStart = periodStart(for: inception, kind: kind, calendar: calendar)

    let anchorStartForEnd = periodStart(for: endAsOf, kind: kind, calendar: calendar)
    let hardStop = nextPeriodStart(after: anchorStartForEnd, kind: kind, calendar: calendar)

    struct Slice {
        let index: Int
        let start: Date
        let endExcl: Date
        let label: String
        let asOf: Date
    }

    var slices: [Slice] = []
    var idx = 0

    while curStart < hardStop {
        let nextStart = nextPeriodStart(after: curStart, kind: kind, calendar: calendar)
        let endExcl = min(nextStart, hardStop)

        let label = labelForPeriodStart(curStart, kind: kind, calendar: calendar)

        // as-of = last day within [curStart, endAsOf], inclusive
        let asOf: Date = {
            if endExcl > endAsOf {
                return endAsOf
            } else {
                // endExcl is start of next period → use previous day
                return calendar.date(byAdding: .day, value: -1, to: endExcl) ?? endExcl
            }
        }()

        slices.append(.init(index: idx, start: curStart, endExcl: endExcl, label: label, asOf: asOf))
        curStart = nextStart
        idx += 1
    }

    if slices.isEmpty { return [] }

    // Parallel assemble per-period bundles
    var out = Array<EquityPeriod?>(repeating: nil, count: slices.count)

    try await withThrowingTaskGroup(of: (Int, EquityPeriod).self) { group in
        for s in slices {
            group.addTask { [s, assemble_async] in
                let bundle = try await assemble_async(s.start, s.endExcl)
                let period = EquityPeriod(label: s.label, bundle: bundle, asOf: s.asOf)
                return (s.index, period)
            }
        }

        for try await (i, p) in group {
            out[i] = p
        }
    }

    return out.compactMap { $0 }
}

public func allocateProfitForPeriod(
    bundle: StatementBundle,
    chart: CompiledChart,
    entities: EntityStore,
    asOf: Date,
    cfg: EquityRollforwardConfig,
    maps: ChartMaps
) throws -> ProfitAllocation {
    // NI total via BusinessEntity defaults
    let ch = try chart.ensuringIndex(enrichNodes: true, strict: false)
    let resolved = try cfg.entity.autoCloseTargets().resolve(in: ch.index!, validateWith: RGSAssembler.makeMaps(from: ch))
    let niId = resolved.ni.id
    let niTotal = bundle.income.first(where: { $0.id == niId })?.amount ?? 0

    // Posted AOW
    let aow = aeMap(bundle: bundle, code: cfg.entity.profitShareCode, maps: maps).mapValues(absD)
    let aowSum = aow.values.reduce(0, +)
    let usePosted = absD(aowSum - niTotal) <= 0.01

    // Ownership slices (ONLY for NI allocation fallback)
    let weights = Dictionary(uniqueKeysWithValues: entities.ownershipSlices(asOf: asOf).map { ($0.entityId, $0.percent) })
    let ownerIds = Set(aow.keys).union(weights.keys)

    var used: [Int: Decimal] = [:], eff: [Int: Decimal] = [:]
    if usePosted {
        for oid in ownerIds {
            let amt = aow[oid] ?? 0
            used[oid] = amt
            eff[oid] = (niTotal == 0) ? 0 : (amt / niTotal)
        }
        return .init(niTotal: niTotal, usePosted: true, usedAmounts: used, effectivePercents: eff, source: .postedAOW)
    } else {
        for oid in ownerIds {
            let p = weights[oid] ?? 0
            let amt = niTotal * p
            used[oid] = amt
            eff[oid] = p
        }
        return .init(niTotal: niTotal, usePosted: false, usedAmounts: used, effectivePercents: eff, source: .slices(asOf: asOf))
    }
}

public func buildOwnerDeltas(
    bundle: StatementBundle,
    chart: CompiledChart,
    entities: EntityStore,
    asOf: Date,
    cfg: EquityRollforwardConfig,
    maps: ChartMaps
) throws -> (owners: [Int], deltas: [Int: OwnerDelta], profit: ProfitAllocation) {
    let prs = aeMap(bundle: bundle, code: cfg.contribCode, maps: maps).mapValues(absD)
    let pro = aeMap(bundle: bundle, code: cfg.drawingCode, maps: maps).mapValues(absD)
    let alloc = try allocateProfitForPeriod(bundle: bundle, chart: chart, entities: entities, asOf: asOf, cfg: cfg, maps: maps)

    let owners = Set(prs.keys).union(pro.keys).union(alloc.usedAmounts.keys).sorted()
    var out: [Int: OwnerDelta] = [:]
    for oid in owners {
        out[oid] = OwnerDelta(stort: prs[oid] ?? 0, onttrek: pro[oid] ?? 0, winst: alloc.usedAmounts[oid] ?? 0)
    }
    return (owners, out, alloc)
}

// ─────────────────────────────────────────────────────────────────────────────
// Owner-tagged closing & earliest opening

@inline(__always)
public func equityAnchorId(cfg: EquityRollforwardConfig, maps: ChartMaps) -> Int? {
    if let id = maps.idByCode[cfg.entity.periodOpeningRouting.equityAnchorCode] { return id }
    if let fallback = cfg.equityTotalFallback, let id = maps.idByCode[fallback] { return id }
    return nil
}

/// Return per-owner closing for the anchor (presentation sign if reconcilable).
public func equityClosingByOwner(
    bundle: StatementBundle,
    cfg: EquityRollforwardConfig,
    maps: ChartMaps
) -> [Int: Decimal] {
    guard let id = equityAnchorId(cfg: cfg, maps: maps),
          let eb = bundle.entity?.byAccount,
          let m  = eb[id]
    else { return [:] }

    var assigned: [Int: Decimal] = [:]
    var unassigned: Decimal = 0
    for (eid, amt) in m {
        if let oid = eid { assigned[oid] = amt } else { unassigned = amt }
    }

    let presClose: Decimal = bundle.balance.first { $0.id == id }?.amount ?? 0
    let sumAssigned = assigned.values.reduce(0, +)
    let sumAll = sumAssigned + unassigned
    let tol: Decimal = 0.01

    if absD(sumAll + presClose) <= tol { return assigned.mapValues { -$0 } } // flip to match presentation
    if absD(sumAll - presClose) <= tol { return assigned }                    // already matches
    if absD(sumAssigned + presClose) <= tol { return assigned.mapValues { -$0 } }
    if absD(sumAssigned - presClose) <= tol { return assigned }
    return assigned // show raw owners if irreconcilable
}

/// Earliest BEGIN: posted opening → else backsolve from per-owner closing − delta → else 0.
public func buildEarliestBeginMap(
    earliest: EquityPeriod,
    chart: CompiledChart,
    entities: EntityStore,
    cfg: EquityRollforwardConfig,
    maps: ChartMaps
) throws -> [Int: Decimal] {
    // 1) owner-tagged opening posted?
    if let eb = earliest.bundle.entity?.byAccount,
       let openingCode = cfg.entity.periodOpeningRouting.equityOpeningCode,
       let begId = maps.idByCode[openingCode],
       let m = eb[begId] {
        let perOwner = Dictionary(uniqueKeysWithValues: m.compactMap { (eid, amt) -> (Int, Decimal)? in
            guard let oid = eid else { return nil }
            return (oid, absD(amt)) // keep positive for begin anchor
        })
        if !perOwner.isEmpty { return perOwner }
    }

    // 2) backsolve from earliest per-owner closing
    let closingByOwner = equityClosingByOwner(bundle: earliest.bundle, cfg: cfg, maps: maps)
    if !closingByOwner.isEmpty {
        let (_, deltas, _) = try buildOwnerDeltas(bundle: earliest.bundle, chart: chart, entities: entities, asOf: earliest.asOf, cfg: cfg, maps: maps)
        let owners = Set(closingByOwner.keys).union(deltas.keys)
        var begin: [Int: Decimal] = [:]
        for oid in owners {
            let close = closingByOwner[oid] ?? 0
            let d = deltas[oid] ?? OwnerDelta(stort: 0, onttrek: 0, winst: 0)
            begin[oid] = close - d.delta
        }
        return begin
    }

    // 3) nothing to backsolve → BEGIN = 0 per owner (owners discovered from movements)
    let (owners, _, _) = try buildOwnerDeltas(bundle: earliest.bundle, chart: chart, entities: entities, asOf: earliest.asOf, cfg: cfg, maps: maps)
    return Dictionary(uniqueKeysWithValues: owners.map { ($0, Decimal(0)) })
}

// Presentation totals for display (not used for per-owner math)
public func equityPresentationTotals(
    periodIndex i: Int,
    periods: [EquityPeriod],
    chart: CompiledChart,
    cfg: EquityRollforwardConfig,
    maps: ChartMaps
) -> (opening: Decimal, closing: Decimal) {
    let eqId = equityAnchorId(cfg: cfg, maps: maps)
    let opening: Decimal = {
        if i == 0 {
            if let openingCode = cfg.entity.periodOpeningRouting.equityOpeningCode,
               let begId = maps.idByCode[openingCode] {
                return periods[i].bundle.balance.first { $0.id == begId }?.amount ?? 0
            } else { return 0 }
        } else {
            guard let eid = eqId else { return 0 }
            return periods[i - 1].bundle.balance.first { $0.id == eid }?.amount ?? 0
        }
    }()
    let closing: Decimal = {
        guard let eid = eqId else { return 0 }
        return periods[i].bundle.balance.first { $0.id == eid }?.amount ?? 0
    }()
    return (opening, closing)
}

public func buildGlobalRollforward(
    history: [EquityPeriod],           // FULL chronological history you want to solve
    chart: CompiledChart,
    entities: EntityStore,
    cfg: EquityRollforwardConfig
) throws -> [PeriodRollforward] {
    precondition(!history.isEmpty, "history must not be empty")

    let maps = ChartMaps(chart: chart)

    // Explain anchor choice
    let earliest = history[0]
    let hasPostedBegin: Bool = {
        if let eb = earliest.bundle.entity?.byAccount,
           let code = cfg.entity.periodOpeningRouting.equityOpeningCode,
           let id = maps.idByCode[code] { return eb[id] != nil }
        return false
    }()
    let hasPerOwnerClosing = !equityClosingByOwner(bundle: earliest.bundle, cfg: cfg, maps: maps).isEmpty

    if hasPostedBegin {
        print("Earliest anchor: owner-tagged opening found — using posted per-owner BEGIN.")
    } else if hasPerOwnerClosing {
        print("Earliest anchor: backsolved from per-owner closing − movements (no % guessing).")
    } else {
        print("Earliest anchor: none posted and no per-owner closing — BEGIN = 0 per owner.")
    }

    // Earliest BEGIN per owner
    var beginByOwner = try buildEarliestBeginMap(earliest: earliest, chart: chart, entities: entities, cfg: cfg, maps: maps)
    rfDumpOwnerMap("BEGIN map for earliest period", map: beginByOwner, entities: entities)

    var out: [PeriodRollforward] = []

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

        // Debug reconciliation against AE closing for this period
        let perOwnerClose = equityClosingByOwner(bundle: p.bundle, cfg: cfg, maps: maps)
        if !perOwnerClose.isEmpty {
            let endSum = endByOwner.values.reduce(0, +)
            let closeSum = perOwnerClose.values.reduce(0, +)
            if absD(endSum - closeSum) > 0.01 {
                rfDbg("[\(p.label)] WARNING: per-owner END sum \(fmtDec(endSum)) ≠ AE closing \(fmtDec(closeSum)); Δ=\(fmtDec(endSum - closeSum))")
                rfDumpOwnerMap("[\(p.label)] per-owner (END − CLOSING)", map: owners.reduce(into: [Int:Decimal]()) { acc, oid in acc[oid] = (endByOwner[oid] ?? 0) - (perOwnerClose[oid] ?? 0) })
            }
        }

        // Carry forward to next period
        beginByOwner = endByOwner
    }

    return out
}

// CONCURRENT VERSION
internal struct EquityPeriodPieces: Sendable {
    let moveOwners: [Int]
    let deltas: [Int: OwnerDelta]
    let alloc: ProfitAllocation
    let closingByOwner: [Int: Decimal]
    let openingTotal: Decimal
    let closingTotal: Decimal
}

public func buildGlobalRollforwardConcurrent(
    history: [EquityPeriod],
    chart: CompiledChart,
    entities: EntityStore,
    cfg: EquityRollforwardConfig
) async throws -> [PeriodRollforward] {
    precondition(!history.isEmpty, "history must not be empty")

    let maps = ChartMaps(chart: chart)
    let earliest = history[0]

    // Same anchor diagnostics as the sync version
    let hasPostedBegin: Bool = {
        if let eb = earliest.bundle.entity?.byAccount,
           let code = cfg.entity.periodOpeningRouting.equityOpeningCode,
           let id = maps.idByCode[code] { return eb[id] != nil }
        return false
    }()
    let hasPerOwnerClosing = !equityClosingByOwner(bundle: earliest.bundle, cfg: cfg, maps: maps).isEmpty

    if hasPostedBegin {
        print("Earliest anchor: owner-tagged opening found — using posted per-owner BEGIN.")
    } else if hasPerOwnerClosing {
        print("Earliest anchor: backsolved from per-owner closing − movements (no % guessing).")
    } else {
        print("Earliest anchor: none posted and no per-owner closing — BEGIN = 0 per owner.")
    }

    // Earliest BEGIN per owner (same helper as sync version)
    var beginByOwner = try buildEarliestBeginMap(
        earliest: earliest,
        chart: chart,
        entities: entities,
        cfg: cfg,
        maps: maps
    )
    rfDumpOwnerMap("BEGIN map for earliest period", map: beginByOwner, entities: entities)

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
                    periods: [period],   // or pass history + i if that function really needs the whole array
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
        let p = history[i]

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

        // Debug reconciliation vs AE closing (same logic, but uses precomputed closingByOwner)
        if !closingByOwner.isEmpty {
            let endSum = endByOwner.values.reduce(0, +)
            let closeSum = closingByOwner.values.reduce(0, +)
            if absD(endSum - closeSum) > 0.01 {
                rfDbg("[\(p.label)] WARNING: per-owner END sum \(fmtDec(endSum)) ≠ AE closing \(fmtDec(closeSum)); Δ=\(fmtDec(endSum - closeSum))")
                rfDumpOwnerMap(
                    "[\(p.label)] per-owner (END − CLOSING)",
                    map: owners.reduce(into: [Int: Decimal]()) { acc, oid in
                        acc[oid] = (endByOwner[oid] ?? 0) - (closingByOwner[oid] ?? 0)
                    },
                    entities: entities
                )
            }
        }

        out.append(row)
        beginByOwner = endByOwner
    }

    return out
}
