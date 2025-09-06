import Foundation

// ─────────────────────────────────────────────────────────────────────────────
// Small utils & formatting

public enum PadAlign { case left, right }
public func pad(_ s: String, _ w: Int, _ a: PadAlign = .left) -> String {
    let len = s.count
    if len >= w { return s }
    let spaces = String(repeating: " ", count: w - len)
    return a == .left ? (s + spaces) : (spaces + s)
}
public func absD(_ x: Decimal) -> Decimal { x < 0 ? -x : x }
public func roundD(_ x: Decimal, digits: Int = 2) -> Decimal {
    var v = x, out = Decimal()
    NSDecimalRound(&out, &v, digits, .plain)
    return out
}
public func fmtDec(_ x: Decimal, digits: Int = 2) -> String {
    let nf = NumberFormatter()
    nf.locale = Locale(identifier: "nl_NL")
    nf.numberStyle = .decimal
    nf.minimumFractionDigits = digits
    nf.maximumFractionDigits = digits
    return nf.string(from: x as NSDecimalNumber) ?? x.description
}
public func fmtPct(_ p: Decimal, digits: Int = 2) -> String {
    "\(fmtDec(roundD(p * 100, digits: digits), digits: digits))%"
}


// ─────────────────────────────────────────────────────────────────────────────

public func earliestPostingDate<Seq: Sequence>(
    in entries: Seq,
    using settings: EntryCompilerSettings
) -> Date? where Seq.Element == Entry {
    return entries.lazy
        .compactMap { $0.resolvedPostingDate(using: settings) }
        .min()
}

public func earliestAbsoluteDate(
    entries: [Entry],
    settings: EntryCompilerSettings
) throws -> Date {
    var minDate: Date?
    for e in entries {
        let spec = try e.date.resolved(for: e, using: settings) // returns .absolute
        if case .absolute(let d) = spec {
            if let cur = minDate {
                if d < cur { minDate = d }
            } else {
                minDate = d
            }
        }
    }
    return minDate ?? Date.distantPast
}

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

// ─────────────────────────────────────────────────────────────────────────────
// Config & period models

public struct EquityRollforwardConfig {
    public var entity: BusinessEntity = .vof
    public var fractionDigits: Int = 2
    public var contribCode: String = "BEivKapPrs"
    public var drawingCode: String = "BEivKapPro"
    public var equityTotalFallback: String? = "BEivKap"
    public init() {}
}

public struct EquityPeriod {
    public let label: String
    public let bundle: StatementBundle
    public let asOf: Date
    public init(label: String, bundle: StatementBundle, asOf: Date) {
        self.label = label; self.bundle = bundle; self.asOf = asOf
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Chart & entity helpers

public struct ChartMaps {
    let idByCode: [String: Int]
    init(chart: CompiledChart) {
        idByCode = Dictionary(uniqueKeysWithValues: chart.nodes.map { ($0.codes.code, $0.id) })
    }
}

public func ownerNameMap(_ entities: EntityStore) -> [Int?: String] {
    var out: [Int?: String] = [nil: "(unassigned)"]
    for (key, id) in entities.idIndex {
        let nm = entities.byFull[key]?.displayName ?? key.identifier(displaying: .fullchain)
        out[id] = nm
    }
    return out
}

/// AE → owner map for a single account code
public func aeMap(bundle: StatementBundle, code: String, maps: ChartMaps) -> [Int: Decimal] {
    guard let eb = bundle.entity?.byAccount,
          let id = maps.idByCode[code],
          let m  = eb[id]
    else { return [:] }
    return Dictionary(uniqueKeysWithValues: m.compactMap { (eid, amt) in
        guard let oid = eid else { return nil }
        return (oid, amt)
    })
}

// ─────────────────────────────────────────────────────────────────────────────
// Profit allocation (posted AOW vs slices)

public enum WinstSource: CustomStringConvertible {
    case postedAOW
    case slices(asOf: Date)
    public var description: String {
        switch self {
        case .postedAOW: return "posted AOW"
        case .slices(let d):
            let df = DateFormatter(); df.locale = Locale(identifier: "nl_NL"); df.dateFormat = "yyyy-MM-dd"
            return "ownership % slices as of \(df.string(from: d))"
        }
    }
}

public struct ProfitAllocation {
    public let niTotal: Decimal
    public let usePosted: Bool
    public let usedAmounts: [Int: Decimal]        // per owner
    public let effectivePercents: [Int: Decimal]  // 0…1
    public let source: WinstSource
    public init(niTotal: Decimal, usePosted: Bool, usedAmounts: [Int: Decimal], effectivePercents: [Int: Decimal], source: WinstSource) {
        self.niTotal = niTotal; self.usePosted = usePosted; self.usedAmounts = usedAmounts; self.effectivePercents = effectivePercents; self.source = source
    }
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

// ─────────────────────────────────────────────────────────────────────────────
// Movements per period

public struct OwnerDelta {
    public let stort: Decimal
    public let onttrek: Decimal
    public let winst: Decimal
    public var delta: Decimal { stort - onttrek + winst }
    public init(stort: Decimal, onttrek: Decimal, winst: Decimal) {
        self.stort = stort; self.onttrek = onttrek; self.winst = winst
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

// ─────────────────────────────────────────────────────────────────────────────
@inline(__always) private func rfDbg(_ s: @autoclosure () -> String) {
    print("[DEBUG] \(s())")
}
public func rfDumpOwnerMap(_ tag: String, map: [Int: Decimal], entities: EntityStore? = nil, digits: Int = 2) {
    let names: [Int?:String] = entities.map { ownerNameMap($0) } ?? [:]
    let total = map.values.reduce(0, +)
    print("[RF-DBG] \(tag): total=\(fmtDec(roundD(total, digits: digits), digits: digits))  owners=\(map.count)")
    for oid in map.keys.sorted() {
        let nm = names[Int?(oid)] ?? "owner#\(oid)"
        let amt = map[oid] ?? 0
        print("         - \(nm): \(fmtDec(roundD(amt, digits: digits), digits: digits))")
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Period rows & printing

public struct PeriodRollforward {
    let owners: [Int]
    let beginByOwner: [Int: Decimal]
    let deltas: [Int: OwnerDelta]
    let endByOwner: [Int: Decimal]
    let niTotal: Decimal
    let winstSource: WinstSource
    let allocationNote: [Int: (percent: Decimal, amount: Decimal)] // 0…1
    let openingTotal: Decimal
    let closingTotal: Decimal
}

public func printHeader(_ title: String) {
    print("\n\(title)")
    print(String(repeating: "—", count: title.count))
}

public func printPeriod(label: String, rows: PeriodRollforward, entities: EntityStore, cfg: EquityRollforwardConfig) {
    let names = ownerNameMap(entities)
    let d = cfg.fractionDigits

    print("\n\(label)")
    print("Winst source: \(rows.winstSource)")
    print("• Net income (total, injected): \(fmtDec(roundD(rows.niTotal, digits: d), digits: d))")
    print("\(pad("Owner", 28)) \(pad("Begin", 14, .right)) \(pad("Stort", 14, .right)) \(pad("Onttrek", 14, .right)) \(pad("Winst", 14, .right)) \(pad("Eind", 14, .right))")

    var tBegin = Decimal(0), tStort = Decimal(0), tOnt = Decimal(0), tWinst = Decimal(0), tEnd = Decimal(0)

    for oid in rows.owners {
        let nm = names[Int?(oid)] ?? "owner#\(oid)"
        let b  = rows.beginByOwner[oid] ?? 0
        let dlt = rows.deltas[oid] ?? OwnerDelta(stort: 0, onttrek: 0, winst: 0)
        let e  = rows.endByOwner[oid] ?? (b + dlt.delta)

        tBegin += b; tStort += dlt.stort; tOnt += dlt.onttrek; tWinst += dlt.winst; tEnd += e

        print("\(pad(nm, 28)) " +
              "\(pad(fmtDec(roundD(b, digits: d), digits: d), 14, .right)) " +
              "\(pad(fmtDec(roundD(dlt.stort, digits: d), digits: d), 14, .right)) " +
              "\(pad(fmtDec(roundD(dlt.onttrek, digits: d), digits: d), 14, .right)) " +
              "\(pad(fmtDec(roundD(dlt.winst, digits: d), digits: d), 14, .right)) " +
              "\(pad(fmtDec(roundD(e, digits: d), digits: d), 14, .right))")
    }

    print(String(repeating: "—", count: 28 + 1 + 14*5))
    print("\(pad("TOTAL", 28)) " +
          "\(pad(fmtDec(roundD(tBegin, digits: d), digits: d), 14, .right)) " +
          "\(pad(fmtDec(roundD(tStort, digits: d), digits: d), 14, .right)) " +
          "\(pad(fmtDec(roundD(tOnt,  digits: d), digits: d), 14, .right)) " +
          "\(pad(fmtDec(roundD(tWinst,digits: d), digits: d), 14, .right)) " +
          "\(pad(fmtDec(roundD(tEnd,  digits: d), digits: d), 14, .right))")

    print("Check totals → Opening: \(fmtDec(roundD(rows.openingTotal, digits: d), digits: d)) | Closing: \(fmtDec(roundD(rows.closingTotal, digits: d), digits: d))")
    print("Identity check: Begin + Stort − Onttrek + Winst = \(fmtDec(roundD(tBegin + tStort - tOnt + tWinst, digits: d), digits: d))")

    if !rows.allocationNote.isEmpty {
        print("NI allocation (used): \(rows.winstSource)")
        for oid in rows.owners {
            let nm = names[Int?(oid)] ?? "owner#\(oid)"
            if let (p, amt) = rows.allocationNote[oid] {
                print("  • \(nm): \(fmtPct(p, digits: d))  →  \(fmtDec(roundD(amt, digits: d), digits: d))")
            }
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// GLOBAL backsolve

/// Build the entire global rollforward once (earliest → latest), carrying END → next BEGIN.
/// Never infers BEGIN by %. Only the earliest BEGIN is anchored (posted/opening or backsolved or 0).
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

// ─────────────────────────────────────────────────────────────────────────────
// Runners

/// Global runner: give me the FULL history; I’ll compute and optionally print a window.
public func runOwnerEquityRollforwardIB_Global(
    title: String = "IB equity rollforward (owner split, backsolved)",
    history: [EquityPeriod],                  // full chronological history
    chart: CompiledChart,
    entities: EntityStore,
    printWindow: Range<Int>? = nil,           // which solved periods to print (default: all)
    config cfg: EquityRollforwardConfig = EquityRollforwardConfig()
) throws {
    guard !history.isEmpty else { printHeader(title); print("(no periods)"); return }
    let solved = try buildGlobalRollforward(history: history, chart: chart, entities: entities, cfg: cfg)

    printHeader(title)

    let window = printWindow ?? history.indices
    for i in window {
        printPeriod(label: history[i].label, rows: solved[i], entities: entities, cfg: cfg)
    }
}

/// Thin wrapper (keeps your current call pattern working).
/// If you can provide full history from the call site, prefer `runOwnerEquityRollforwardIB_Global(...)`.
public func runOwnerEquityRollforwardIB(
    title: String = "IB equity rollforward (owner split, backsolved)",
    current cur: StatementBundle,
    previous prv: StatementBundle?,
    chart: CompiledChart,
    entities: EntityStore,
    asOfCurrent: Date,
    asOfPrevious: Date?,
    history: [EquityPeriod]? = nil,           // ← pass full history here if you have it
    config cfg: EquityRollforwardConfig = EquityRollforwardConfig()
) throws {
    // If caller already built full history, use it
    if let hist = history, !hist.isEmpty {
        try runOwnerEquityRollforwardIB_Global(title: title, history: hist, chart: chart, entities: entities, printWindow: nil, config: cfg)
        return
    }

    // Otherwise, fall back to the two-period window (still solved globally over these)
    var periods: [EquityPeriod] = []
    if let p = prv, let pd = asOfPrevious { periods.append(.init(label: "Previous", bundle: p, asOf: pd)) }
    periods.append(.init(label: "Current", bundle: cur, asOf: asOfCurrent))

    try runOwnerEquityRollforwardIB_Global(title: title, history: periods, chart: chart, entities: entities, printWindow: nil, config: cfg)
}

/// Print owner equity rollforward using *global* backsolve across `allPeriods`,
/// but only render rows for indices in `view` (e.g. previous+current).
public func runOwnerEquityRollforwardHistory(
    title: String = "IB equity rollforward (owner split, backsolved)",
    allPeriods: [EquityPeriod],
    chart: CompiledChart,
    entities: EntityStore,
    view: ClosedRange<Int>?,                 // nil → print all
    config cfg: EquityRollforwardConfig = .init()
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

        // Only print when within the requested view window (but always carry forward)
        if view == nil || view!.contains(i) {
            printPeriod(label: p.label, rows: rows, entities: entities, cfg: cfg)
        }

        beginByOwner = endByOwner
    }
}

