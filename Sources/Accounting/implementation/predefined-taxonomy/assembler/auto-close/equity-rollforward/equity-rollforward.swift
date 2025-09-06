import Foundation

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

/// Knobs for the rollforward; codes are sourced from BusinessEntity defaults.
public struct EquityRollforwardConfig {
    public var entity: BusinessEntity = .vof
    public var fractionDigits: Int = 2

    // parents for contributions/drawings (owner-tagged at parent)
    // Not provided by BusinessEntity yet; keep overridable here.
    public var contribCode: String = "BEivKapPrs"
    public var drawingCode: String = "BEivKapPro"

    // optional fallback for equity total (some charts prefer BEivKap)
    public var equityTotalFallback: String? = "BEivKap"

    public init() {}
}

/// One period input (label + bundle + as-of date for ownership slices)
public struct EquityPeriod {
    public let label: String
    public let bundle: StatementBundle
    public let asOf: Date
    public init(label: String, bundle: StatementBundle, asOf: Date) {
        self.label = label; self.bundle = bundle; self.asOf = asOf
    }
}

// MARK: - Chart & entity helpers

/// Simple chart maps
public struct ChartMaps {
    let idByCode: [String: Int]
    init(chart: CompiledChart) {
        idByCode = Dictionary(uniqueKeysWithValues: chart.nodes.map { ($0.codes.code, $0.id) })
    }
}
/// Resolve pretty names for owners
public func ownerNameMap(_ entities: EntityStore) -> [Int?: String] {
    var out: [Int?: String] = [nil: "(unassigned)"]
    for (key, id) in entities.idIndex {
        let nm = entities.byFull[key]?.displayName ?? key.identifier(displaying: .fullchain)
        out[id] = nm
    }
    return out
}
/// AE breakdown: account code → [ownerId: amount]
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

// MARK: - Profit allocation (posted AOW vs slices)

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
    
    public init(
        niTotal: Decimal,
        usePosted: Bool,
        usedAmounts: [Int: Decimal],        // per owner,
        effectivePercents: [Int: Decimal],  // 0…1,
        source: WinstSource
    ) {
        self.niTotal = niTotal
        self.usePosted = usePosted
        self.usedAmounts = usedAmounts
        self.effectivePercents = effectivePercents
        self.source = source
    }
}

/// Decide how to allocate NI this period using BusinessEntity defaults.
public func allocateProfitForPeriod(
    bundle: StatementBundle,
    chart: CompiledChart,
    entities: EntityStore,
    asOf: Date,
    cfg: EquityRollforwardConfig,
    maps: ChartMaps
) throws -> ProfitAllocation {
    // NI total via autoCloseTargets()
    let ch = try chart.ensuringIndex(enrichNodes: true, strict: false)
    let targets = cfg.entity.autoCloseTargets()
    let resolved = try targets.resolve(in: ch.index!, validateWith: RGSAssembler.makeMaps(from: ch))
    let niId = resolved.ni.id
    let niTotal = bundle.income.first(where: { $0.id == niId })?.amount ?? 0

    // Posted AOW (BusinessEntity.profitShareCode)
    let aow = aeMap(bundle: bundle, code: cfg.entity.profitShareCode, maps: maps).mapValues(absD)
    let aowSum = aow.values.reduce(0, +)
    let usePosted = absD(aowSum - niTotal) <= 0.01

    // Ownership slices
    let weights = Dictionary(uniqueKeysWithValues: entities.ownershipSlices(asOf: asOf).map { ($0.entityId, $0.percent) })
    let ownerIds = Set(aow.keys).union(weights.keys)

    var usedAmounts: [Int: Decimal] = [:]
    var effPct: [Int: Decimal] = [:]

    if usePosted {
        for oid in ownerIds {
            let amt = aow[oid] ?? 0
            usedAmounts[oid] = amt
            effPct[oid] = (niTotal == 0) ? 0 : (amt / niTotal)
        }
        return ProfitAllocation(niTotal: niTotal, usePosted: true, usedAmounts: usedAmounts, effectivePercents: effPct, source: .postedAOW)
    } else {
        for oid in ownerIds {
            let p = weights[oid] ?? 0
            let amt = niTotal * p
            usedAmounts[oid] = amt
            effPct[oid] = p
        }
        return ProfitAllocation(niTotal: niTotal, usePosted: false, usedAmounts: usedAmounts, effectivePercents: effPct, source: .slices(asOf: asOf))
    }
}

// MARK: - Movements per period

public struct OwnerDelta {
    public let stort: Decimal
    public let onttrek: Decimal
    public let winst: Decimal
    public var delta: Decimal { stort - onttrek + winst }
    
    public init(
        stort: Decimal,
        onttrek: Decimal,
        winst: Decimal,
    ) {
        self.stort = stort
        self.onttrek = onttrek
        self.winst = winst
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

public func buildEarliestBeginMap(
    earliest: EquityPeriod,
    chart: CompiledChart,
    entities: EntityStore,
    cfg: EquityRollforwardConfig,
    maps: ChartMaps
) throws -> [Int: Decimal] {
    // 1) Owner-tagged opening present? Use verbatim (treated as presentation sign).
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

    // 2) Backsolve: begin = closing(normalized to presentation) − delta
    let closingByOwner = equityClosingByOwner(bundle: earliest.bundle, cfg: cfg, maps: maps)
    if !closingByOwner.isEmpty {
        let (_, deltas, _) = try buildOwnerDeltas(
            bundle: earliest.bundle,
            chart: chart,
            entities: entities,
            asOf: earliest.asOf,
            cfg: cfg,
            maps: maps
        )
        let owners = Set(closingByOwner.keys).union(deltas.keys)
        var begin: [Int: Decimal] = [:]
        for oid in owners {
            let close = closingByOwner[oid] ?? 0
            let d = deltas[oid] ?? OwnerDelta(stort: 0, onttrek: 0, winst: 0)
            begin[oid] = close - d.delta
        }
        return begin
    }

    // 3) Nothing to backsolve → BEGIN = 0 per owner (discover owners from movements)
    let (owners, _, _) = try buildOwnerDeltas(
        bundle: earliest.bundle, chart: chart, entities: entities, asOf: earliest.asOf, cfg: cfg, maps: maps
    )
    return Dictionary(uniqueKeysWithValues: owners.map { ($0, Decimal(0)) })
}

public func equityPresentationTotals(
    periodIndex i: Int,
    periods: [EquityPeriod],
    chart: CompiledChart,
    cfg: EquityRollforwardConfig,
    maps: ChartMaps
) -> (opening: Decimal, closing: Decimal) {
    // Primary equity total id (use BusinessEntity anchor code; fallback if provided)
    let eqId = equityAnchorId(cfg: cfg, maps: maps)

    let opening: Decimal = {
        if i == 0 {
            // Only use the opening begin line if we actually have a code configured & mapped
            if let openingCode = cfg.entity.periodOpeningRouting.equityOpeningCode,
               let begId = maps.idByCode[openingCode] {
                return periods[i].bundle.balance.first { $0.id == begId }?.amount ?? 0
            } else {
                return 0
            }
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

// MARK: - Printer

public struct PeriodRollforward {
    let owners: [Int]
    let beginByOwner: [Int: Decimal]
    let deltas: [Int: OwnerDelta]
    let endByOwner: [Int: Decimal]
    let niTotal: Decimal
    let winstSource: WinstSource
    let allocationNote: [Int: (percent: Decimal, amount: Decimal)] // percent 0…1
    let openingTotal: Decimal
    let closingTotal: Decimal
}

public func printHeader(_ title: String) {
    print("\n\(title)")
    print(String(repeating: "—", count: title.count))
}

public func printPeriod(
    label: String,
    rows: PeriodRollforward,
    entities: EntityStore,
    cfg: EquityRollforwardConfig
) {
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
        let dlt = rows.deltas[oid]!
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

    // Allocation note: % and € per owner used for NI this period
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

// MARK: - Orchestrator

/// Main entry (drop-in). Never guesses opening by %; carries ends forward across periods.
public func runOwnerEquityRollforwardIB(
    title: String = "IB equity rollforward (owner split, backsolved)",
    current cur: StatementBundle,
    previous prv: StatementBundle?,            // pass if you compiled with --compare
    chart: CompiledChart,
    entities: EntityStore,
    asOfCurrent: Date,
    asOfPrevious: Date?,                      // usually assembled.previous?.range.to
    config cfg: EquityRollforwardConfig = EquityRollforwardConfig()
) throws {
    var periods: [EquityPeriod] = []
    if let p = prv, let pd = asOfPrevious { periods.append(.init(label: "Previous", bundle: p, asOf: pd)) }
    periods.append(.init(label: "Current", bundle: cur, asOf: asOfCurrent))
    guard !periods.isEmpty else {
        printHeader(title); print("(no periods)"); return
    }

    let maps = ChartMaps(chart: chart)
    let earliest = periods[0]

    // Decide & print anchor mode *before* we compute the begin map
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

    // Compute earliest BEGIN by the same logic
    var beginByOwner = try buildEarliestBeginMap(
        earliest: earliest, chart: chart, entities: entities, cfg: cfg, maps: maps
    )

    for (i, p) in periods.enumerated() {
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
            periodIndex: i, periods: periods, chart: chart, cfg: cfg, maps: maps
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

        printPeriod(label: p.label, rows: rows, entities: entities, cfg: cfg)

        beginByOwner = endByOwner // carry forward exact per-owner end
    }
}

public func equityClosingByOwner(
    bundle: StatementBundle,
    cfg: EquityRollforwardConfig,
    maps: ChartMaps
) -> [Int: Decimal] {
    guard let id = equityAnchorId(cfg: cfg, maps: maps),
          let eb = bundle.entity?.byAccount,
          let m  = eb[id]
    else { return [:] }

    // AE map (owner -> signed amount in AE)
    var raw: [Int: Decimal] = [:]
    for (eid, amt) in m {
        if let oid = eid { raw[oid] = amt }
    }

    // Presentation total from Balance for the same anchor
    let presClose: Decimal = bundle.balance.first { $0.id == id }?.amount ?? 0
    let rawSum = raw.values.reduce(0, +)
    let tol: Decimal = 0.01

    // If AE equals the negative of presentation, flip to match presentation sign
    if absD(rawSum + presClose) <= tol {
        return raw.mapValues { -$0 }
    }
    // If AE already equals presentation, keep as-is
    if absD(rawSum - presClose) <= tol {
        return raw
    }
    // If we can’t reconcile, return raw (better to see it than hide it)
    return raw
}

@inline(__always)
public func equityAnchorId(
    cfg: EquityRollforwardConfig,
    maps: ChartMaps
) -> Int? {
    if let id = maps.idByCode[cfg.entity.periodOpeningRouting.equityAnchorCode] {
        return id
    }
    if let fallback = cfg.equityTotalFallback,
       let id = maps.idByCode[fallback] {
        return id
    }
    return nil
}

