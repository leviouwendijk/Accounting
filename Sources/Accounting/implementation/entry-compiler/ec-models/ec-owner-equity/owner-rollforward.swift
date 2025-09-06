// import Foundation
// import Accounting

// public struct OwnerRollforwardRow {
//     public let ownerId: Int
//     public let ownerName: String
//     public let begin: Decimal
//     public let stort: Decimal
//     public let onttrek: Decimal
//     public let winst: Decimal
//     public var end: Decimal { begin + stort - onttrek + winst }
// }

// /// IB-style owner equity rollforward printer.
// /// - Parameters:
// ///   - niTotal: If provided, scales AOW % to this net income total (recommended).
// ///              If nil, tries AOW sums directly (use only if your assembler already mirrors NI into equity in the entity map).
// public func printOwnerEquityRollforwardIB(
//     _ title: String = "Owner equity rollforward (IB)",
//     bundle: StatementBundle,
//     chart: CompiledChart,
//     entities: EntityStore,
//     niTotal: Decimal? = nil,
//     openEquityCode: String = "BEivKapOndBeg",
//     contribRoot: String = "BEivKapPrs",
//     drawRoot: String = "BEivKapPro",
//     profitShareCode: String = "BEivKapOndAow",
//     fractionDigits: Int = 2,
//     warnIfFallback: Bool = true
// ) {
//     func round2(_ x: Decimal, _ fd: Int) -> Decimal {
//         var v = x, out = Decimal()
//         NSDecimalRound(&out, &v, fd, .plain); return out
//     }
//     func fmt(_ x: Decimal) -> String {
//         let nf = NumberFormatter()
//         nf.locale = Locale(identifier: "nl_NL")
//         nf.numberStyle = .decimal
//         nf.minimumFractionDigits = fractionDigits
//         nf.maximumFractionDigits = fractionDigits
//         return nf.string(from: x as NSDecimalNumber) ?? x.description
//     }

//     guard let eb = bundle.entity else {
//         print("\n\(title)\n\(String(repeating: "—", count: title.count))")
//         print("(no entity breakdown)"); return
//     }

//     // Indexes
//     let nodes = chart.nodes
//     let idByCode: [String:Int] = Dictionary(uniqueKeysWithValues: nodes.map { ($0.codes.code, $0.id) })
//     let labelById: [Int:String] = Dictionary(uniqueKeysWithValues: nodes.map { ($0.id, $0.labels.short) })

//     // Hierarchy maps (for subtrees)
//     let maps = try? RGSAssembler.makeMaps(from: chart)
//     let parentById = maps?.parentById ?? [:]
//     var childrenByParent: [Int:[Int]] = [:]
//     for (child, parent) in parentById { childrenByParent[parent, default: []].append(child) }

//     func descendants(of root: Int) -> [Int] {
//         var out: [Int] = [], stack = [root]
//         while let cur = stack.popLast() {
//             out.append(cur)
//             if let kids = childrenByParent[cur] { stack.append(contentsOf: kids) }
//         }
//         return out
//     }

//     // Helper: sum by entity for a set of account ids
//     func sumByEntity(_ accIds: [Int]) -> [Int?: Decimal] {
//         var acc: [Int?: Decimal] = [:]
//         for aid in accIds {
//             guard let m = eb.byAccount[aid] else { continue }
//             for (eid, v) in m { acc[eid, default: 0] += v }
//         }
//         return acc
//     }

//     // Lookup IDs we need (skip if missing)
//     guard let prId  = idByCode[contribRoot],
//           let poId  = idByCode[drawRoot],
//           let aowId = idByCode[profitShareCode]
//     else {
//         print("\n\(title)\n\(String(repeating: "—", count: title.count))")
//         print("Missing one or more required codes in chart: \(contribRoot), \(drawRoot), \(profitShareCode)")
//         return
//     }
//     let begId = idByCode[openEquityCode] // may be nil

//     // Build the subtrees we need
//     let contribIds = descendants(of: prId)
//     let drawIds    = descendants(of: poId)
//     let aowIds     = [aowId] // not rolling children unless you need them

//     // Gather maps
//     let rawContrib = sumByEntity(contribIds) // Privé-stortingen
//     let rawDraw    = sumByEntity(drawIds)    // Privé-opnamen
//     let rawAOW     = sumByEntity(aowIds)     // Aandeel in de overwinst

//     let owners: [Int] = {
//         var s = Set<Int>()
//         for k in rawContrib.keys { if let x = k { s.insert(x) } }
//         for k in rawDraw.keys    { if let x = k { s.insert(x) } }
//         for k in rawAOW.keys     { if let x = k { s.insert(x) } }
//         return Array(s).sorted()
//     }()

//     // Name map (incl. nil)
//     let idx = entities.idIndex
//     var idToName: [Int?: String] = [nil: "(unassigned)"]
//     for (key, id) in idx {
//         let display = entities.byFull[key]?.displayName
//             ?? key.identifier(displaying: .fullchain)
//         idToName[id] = display
//     }

//     // Normalize signs to IB semantics:
//     //  - Stortingen should be POSITIVE amounts that INCREASE equity.
//     //    In your entity split, they typically appear NEGATIVE → invert.
//     //  - Onttrekkingen should be POSITIVE amounts that DECREASE equity → keep positive.
//     //  - Winst should be POSITIVE to INCREASE equity (AOW may show negative → invert).
//     func pos(_ x: Decimal) -> Decimal { x < 0 ? -x : x }
//     let stortByOwner  = owners.reduce(into: [Int: Decimal]()) { out, eid in
//         let v = rawContrib[Int?(eid)] ?? 0
//         out[eid] = v < 0 ? -v : v // invert if negative
//     }
//     let onttrekByOwner = owners.reduce(into: [Int: Decimal]()) { out, eid in
//         let v = rawDraw[Int?(eid)] ?? 0
//         out[eid] = v < 0 ? -v : v // keep positive; if negative for some reason, invert
//     }

//     // Profit shares (weights) from AOW split by owner (abs), normalized
//     let aowAbsByOwner = owners.map { ($0, pos(rawAOW[Int?($0)] ?? 0)) }
//     let aowAbsSum = aowAbsByOwner.reduce(Decimal(0)) { $0 + $1.1 }
//     let weights: [Int: Decimal] = {
//         if aowAbsSum == 0 {
//             // fallback equal weights
//             let w = owners.isEmpty ? 0 : (1 / Decimal(owners.count))
//             return Dictionary(uniqueKeysWithValues: owners.map { ($0, w) })
//         } else {
//             return Dictionary(uniqueKeysWithValues: aowAbsByOwner.map { ($0.0, ($0.1 / aowAbsSum)) })
//         }
//     }()

//     // Determine NI total
//     let niFromAOW = aowAbsSum // treat as positive
//     let ni: Decimal = {
//         if let x = niTotal { return x }
//         if warnIfFallback {
//             let info = labelById[aowId] ?? profitShareCode
//             fputs("[warn] niTotal not provided; falling back to AOW sum (\(info)) = \(niFromAOW)\n", stderr)
//         }
//         return niFromAOW
//     }()

//     // Allocate profit
//     let winstByOwner = Dictionary(uniqueKeysWithValues:
//         owners.map { ($0, (ni * (weights[$0] ?? 0))) }
//     )

//     // Begin per owner: try opening equity by entity; else pro-rata by weights over total begin
//     var beginTotal: Decimal = 0
//     var beginByOwner = Dictionary(uniqueKeysWithValues: owners.map { ($0, Decimal(0)) })
//     if let bid = begId, let m = eb.byAccount[bid] {
//         beginTotal = m.values.reduce(Decimal(0), +)
//         // extract per-owner if present
//         var seenAnyOwnerTagged = false
//         for oid in owners {
//             if let v = m[Int?(oid)] {
//                 beginByOwner[oid] = v < 0 ? -v : v // ensure positive; opening should add to equity
//                 seenAnyOwnerTagged = true
//             }
//         }
//         if !seenAnyOwnerTagged {
//             // allocate beginTotal by AOW weights
//             for oid in owners { beginByOwner[oid] = beginTotal * (weights[oid] ?? 0) }
//         }
//     } else {
//         // No opening account present → infer from rollforward algebra on totals
//         // Compute begin total from totals if possible (stort/onttrek/winst + end = begin):
//         // endTotal we can infer from BS equity subtotal—but we don’t have it here reliably.
//         // Fall back to 0 and rely on rollforward still balancing per owner deltas.
//         beginTotal = 0
//         for oid in owners { beginByOwner[oid] = 0 }
//         if warnIfFallback { fputs("[warn] opening equity code \(openEquityCode) not present; Begin assumed 0 per owner\n", stderr) }
//     }

//     // Rows
//     var rows: [OwnerRollforwardRow] = []
//     for oid in owners {
//         let nm    = idToName[Int?(oid)] ?? "owner#\(oid)"
//         let begin = beginByOwner[oid] ?? 0
//         let stort = stortByOwner[oid] ?? 0
//         let ontr  = onttrekByOwner[oid] ?? 0
//         let winst = winstByOwner[oid] ?? 0
//         rows.append(.init(ownerId: oid, ownerName: nm, begin: begin, stort: stort, onttrek: ontr, winst: winst))
//     }

//     // Totals (sanity)
//     let tBegin = rows.reduce(Decimal(0)) { $0 + $1.begin }
//     let tStort = rows.reduce(Decimal(0)) { $0 + $1.stort }
//     let tOnt   = rows.reduce(Decimal(0)) { $0 + $1.onttrek }
//     let tWinst = rows.reduce(Decimal(0)) { $0 + $1.winst }
//     let tEnd   = rows.reduce(Decimal(0)) { $0 + $1.end }

//     // Print
//     print("\n\(title)")
//     print(String(repeating: "—", count: title.count))
//     print(String(format: "%-28s %14s %14s %14s %14s %14s",
//                  "Owner", "Begin", "Stort", "Onttrek", "Winst", "Eind"))

//     for r in rows {
//         print(String(format: "%-28s %14s %14s %14s %14s %14s",
//                      r.ownerName,
//                      fmt(round2(r.begin, fractionDigits)),
//                      fmt(round2(r.stort, fractionDigits)),
//                      fmt(round2(r.onttrek, fractionDigits)),
//                      fmt(round2(r.winst, fractionDigits)),
//                      fmt(round2(r.end, fractionDigits))))
//     }

//     print(String(repeating: "—", count: 28 + 1 + 14*5))
//     print(String(format: "%-28s %14s %14s %14s %14s %14s",
//                  "TOTAL",
//                  fmt(round2(tBegin, fractionDigits)),
//                  fmt(round2(tStort, fractionDigits)),
//                  fmt(round2(tOnt,   fractionDigits)),
//                  fmt(round2(tWinst, fractionDigits)),
//                  fmt(round2(tEnd,   fractionDigits))))
//     print()
// }

// import Foundation

// public enum PadAlign { case left, right }
// public func pad(_ s: String, _ w: Int, _ a: PadAlign = .left) -> String {
//     let len = s.count
//     if len >= w { return s }
//     let spaces = String(repeating: " ", count: w - len)
//     return a == .left ? (s + spaces) : (spaces + s)
// }
// public func absD(_ x: Decimal) -> Decimal { x < 0 ? -x : x }
// public func roundD(_ x: Decimal, digits: Int = 2) -> Decimal {
//     var v = x, out = Decimal()
//     NSDecimalRound(&out, &v, digits, .plain)
//     return out
// }
// public func fmtDec(_ x: Decimal, digits: Int = 2) -> String {
//     let nf = NumberFormatter()
//     nf.locale = Locale(identifier: "nl_NL")
//     nf.numberStyle = .decimal
//     nf.minimumFractionDigits = digits
//     nf.maximumFractionDigits = digits
//     return nf.string(from: x as NSDecimalNumber) ?? x.description
// }
// public func fmtPct(_ p: Decimal, digits: Int = 2) -> String {
//     return "\(fmtDec(roundD(p * 100, digits: digits), digits: digits))%"
// }

// // MARK: - Domain structs

// /// Accounts/codes used by the rollforward.
// public struct EquityCodes {
//     // Presentation (totals)
//     let equityTotal: String         // prefer "BEivKap"
//     let equityTotalFallback: String // fallback "BEiv"

//     // Opening (owner-tagged begin candidates)
//     let beginCandidates: [String]   // e.g. ["BEivKapOndBeg", "BEivKapBeg", "BEivBeg"]

//     // Entity-breakdown (parents only)
//     let contrib: String             // "BEivKapPrs"
//     let drawing: String             // "BEivKapPro"
//     let postedAOW: String           // "BEivKapOndAow"

//     public static let DefaultEquityCodes = EquityCodes(
//         equityTotal: "BEivKap",
//         equityTotalFallback: "BEiv",
//         beginCandidates: ["BEivKapOndBeg", "BEivKapBeg", "BEivBeg"],
//         contrib: "BEivKapPrs",
//         drawing: "BEivKapPro",
//         postedAOW: "BEivKapOndAow"
//     )
// }



// /// Config knobs
// public struct EquityRollforwardConfig {
//     public var entity: BusinessEntity = .vof
//     public var fractionDigits: Int = 2
//     public var codes: EquityCodes = DefaultEquityCodes
//     public init() {}
// }

// /// One period input (label + bundle + as-of date for ownership slices)
// public struct EquityPeriod {
//     public let label: String
//     public let bundle: StatementBundle
//     public let asOf: Date
//     public init(label: String, bundle: StatementBundle, asOf: Date) {
//         self.label = label; self.bundle = bundle; self.asOf = asOf
//     }
// }

// /// Movement per owner for a period
// public struct OwnerDelta {
//     let stort: Decimal
//     let onttrek: Decimal
//     let winst: Decimal
//     var delta: Decimal { stort - onttrek + winst }
// }

// /// Data needed to print a single period
// public struct PeriodRollforward {
//     let owners: [Int]
//     let beginByOwner: [Int: Decimal]
//     let endByOwner: [Int: Decimal]
//     let deltas: [Int: OwnerDelta]
//     let niTotal: Decimal
//     let winstSource: WinstSource
//     let allocationNote: [Int: (percent: Decimal, amount: Decimal)] // percent is 0…1
//     let openingTotal: Decimal
//     let closingTotal: Decimal
// }

// /// How we allocated NI this period
// public enum WinstSource: CustomStringConvertible {
//     case postedAOW
//     case slices(asOf: Date)
//     var description: String {
//         switch self {
//         case .postedAOW: return "posted AOW"
//         case .slices(let d):
//             let df = DateFormatter(); df.locale = Locale(identifier: "nl_NL"); df.dateFormat = "yyyy-MM-dd"
//             return "ownership % slices as of \(df.string(from: d))"
//         }
//     }
// }

// // MARK: - Map helpers

// /// Map chart code → id, id → label
// public struct ChartMaps {
//     let idByCode: [String: Int]
//     let labelById: [Int: String]
//     init(chart: CompiledChart) {
//         let nodes = chart.nodes
//         idByCode = Dictionary(uniqueKeysWithValues: nodes.map { ($0.codes.code, $0.id) })
//         labelById = Dictionary(uniqueKeysWithValues: nodes.map { ($0.id, $0.labels.short) })
//     }
// }

// /// Owner name resolver from EntityStore
// public func ownerNameMap(_ entities: EntityStore) -> [Int?: String] {
//     var out: [Int?: String] = [nil: "(unassigned)"]
//     let idx = entities.idIndex
//     for (key, id) in idx {
//         let nm = entities.byFull[key]?.displayName ?? key.identifier(displaying: .fullchain)
//         out[id] = nm
//     }
//     return out
// }

// /// Read an AE (entity breakdown) map for account code → [ownerId: amount]
// public func aeMap(
//     bundle: StatementBundle,
//     code: String,
//     maps: ChartMaps
// ) -> [Int: Decimal] {
//     guard
//         let eb = bundle.entity?.byAccount,
//         let id = maps.idByCode[code],
//         let m = eb[id]
//     else { return [:] }
//     // filter nil keys; keep raw sign
//     return Dictionary(uniqueKeysWithValues: m.compactMap { (eid, amt) in
//         guard let oid = eid else { return nil }
//         return (oid, amt)
//     })
// }

// // MARK: - Profit allocation (posted AOW vs slices)

// public struct ProfitAllocation {
//     let niTotal: Decimal
//     let usePosted: Bool
//     let usedAmounts: [Int: Decimal]     // per owner winst actually used
//     let effectivePercents: [Int: Decimal] // per owner percent used (0…1), derived from used amounts
//     let source: WinstSource
// }

// /// Decide how to allocate NI for a period, returning amounts + percents per owner.
// public func allocateProfitForPeriod(
//     bundle: StatementBundle,
//     chart: CompiledChart,
//     entities: EntityStore,
//     asOf: Date,
//     cfg: EquityRollforwardConfig,
//     maps: ChartMaps
// ) throws -> ProfitAllocation {
//     // total NI injected from P&L
//     let ch = try chart.ensuringIndex(enrichNodes: true, strict: false)
//     let r = try AutoCloseTargets(for: cfg.entity).resolve(in: ch.index!, validateWith: RGSAssembler.makeMaps(from: ch))
//     let niId = r.ni.id
//     let niTotal = bundle.income.first(where: { $0.id == niId })?.amount ?? 0

//     // posted AOW (owner-tagged in AE)
//     let aowPosted = aeMap(bundle: bundle, code: cfg.codes.postedAOW, maps: maps).mapValues(absD)
//     let aowSum = aowPosted.values.reduce(0, +)

//     // decide source
//     let tol: Decimal = 0.01
//     let usePosted = absD(aowSum - niTotal) <= tol

//     // build owner universe for allocation
//     let slices = entities.ownershipSlices(asOf: asOf)
//     let weights = Dictionary(uniqueKeysWithValues: slices.map { ($0.entityId, $0.percent) })
//     let ownerIds = Set(aowPosted.keys).union(weights.keys)

//     // compute used amounts + percents
//     var usedAmounts: [Int: Decimal] = [:]
//     var effPct: [Int: Decimal] = [:]

//     if usePosted {
//         for oid in ownerIds {
//             let amt = aowPosted[oid] ?? 0
//             usedAmounts[oid] = amt
//             effPct[oid] = (niTotal == 0) ? 0 : (amt / niTotal)
//         }
//         return ProfitAllocation(niTotal: niTotal, usePosted: true, usedAmounts: usedAmounts, effectivePercents: effPct, source: .postedAOW)
//     } else {
//         for oid in ownerIds {
//             let p = weights[oid] ?? 0
//             let amt = niTotal * p
//             usedAmounts[oid] = amt
//             effPct[oid] = p
//         }
//         return ProfitAllocation(niTotal: niTotal, usePosted: false, usedAmounts: usedAmounts, effectivePercents: effPct, source: .slices(asOf: asOf))
//     }
// }

// // MARK: - Movements builder

// /// Build per-owner movements (stort/onttrek/winst) for the period.
// public func buildOwnerDeltas(
//     bundle: StatementBundle,
//     chart: CompiledChart,
//     entities: EntityStore,
//     asOf: Date,
//     cfg: EquityRollforwardConfig,
//     maps: ChartMaps
// ) throws -> (owners: [Int], deltas: [Int: OwnerDelta], profit: ProfitAllocation) {
//     // contributions + drawings (parents only; make positive magnitudes)
//     let prs = aeMap(bundle: bundle, code: cfg.codes.contrib, maps: maps).mapValues(absD)
//     let pro = aeMap(bundle: bundle, code: cfg.codes.drawing, maps: maps).mapValues(absD)

//     // profit allocation decision
//     let alloc = try allocateProfitForPeriod(bundle: bundle, chart: chart, entities: entities, asOf: asOf, cfg: cfg, maps: maps)

//     // owners involved this period
//     let owners = Set(prs.keys).union(pro.keys).union(alloc.usedAmounts.keys).sorted()

//     // assemble deltas
//     var out: [Int: OwnerDelta] = [:]
//     for oid in owners {
//         out[oid] = OwnerDelta(
//             stort: prs[oid] ?? 0,
//             onttrek: pro[oid] ?? 0,
//             winst: alloc.usedAmounts[oid] ?? 0
//         )
//     }
//     return (owners, out, alloc)
// }

// // MARK: - Opening anchor (earliest period only)

// /// Try to read owner-tagged opening postings; otherwise anchor zero per owner (no % guesses).
// public func buildEarliestBeginMap(
//     earliest: EquityPeriod,
//     chart: CompiledChart,
//     cfg: EquityRollforwardConfig,
//     maps: ChartMaps,
//     probeOwnersWith bundleForProbe: StatementBundle, asOf probeAsOf: Date,
//     entities: EntityStore
// ) throws -> [Int: Decimal] {
//     // 1) Owner-tagged opening postings on known "begin" codes
//     if let eb = earliest.bundle.entity?.byAccount {
//         for code in cfg.codes.beginCandidates {
//             if let id = maps.idByCode[code], let m = eb[id] {
//                 let perOwner = Dictionary(uniqueKeysWithValues: m.compactMap { (eid, amt) in
//                     eid.map { ($0, absD(amt)) }
//                 })
//                 if !perOwner.isEmpty { return perOwner }
//             }
//         }
//     }
//     // 2) If none, anchor zero per owner discovered from earliest movements
//     let (owners, _, _) = try buildOwnerDeltas(bundle: bundleForProbe, chart: chart, entities: entities, asOf: probeAsOf, cfg: cfg, maps: maps)
//     return Dictionary(uniqueKeysWithValues: owners.map { ($0, Decimal(0)) })
// }

// // MARK: - Presentation totals (Balance Sheet lines)

// public func equityPresentationTotals(
//     periodIndex i: Int,
//     periods: [EquityPeriod],
//     chart: CompiledChart,
//     cfg: EquityRollforwardConfig,
//     maps: ChartMaps
// ) -> (opening: Decimal, closing: Decimal) {
//     guard let eqId = (maps.idByCode[cfg.codes.equityTotal] ?? maps.idByCode[cfg.codes.equityTotalFallback]) else {
//         return (0, 0)
//     }
//     // opening: earliest uses begin line if present; others use previous closing
//     let opening: Decimal = {
//         if i == 0 {
//             if let begId = maps.idByCode[cfg.codes.beginCandidates.first ?? ""] {
//                 return periods[i].bundle.balance.first { $0.id == begId }?.amount ?? 0
//             } else {
//                 return 0
//             }
//         } else {
//             return periods[i - 1].bundle.balance.first { $0.id == eqId }?.amount ?? 0
//         }
//     }()
//     let closing: Decimal = periods[i].bundle.balance.first { $0.id == eqId }?.amount ?? 0
//     return (opening, closing)
// }

// // MARK: - Printer

// public func printRollforwardHeader(_ title: String) {
//     print("\n\(title)")
//     print(String(repeating: "—", count: title.count))
// }

// public func printPeriodTable(
//     label: String,
//     rows: PeriodRollforward,
//     entities: EntityStore,
//     cfg: EquityRollforwardConfig
// ) {
//     let names = ownerNameMap(entities)
//     let d = cfg.fractionDigits

//     print("\n\(label)")
//     print("Winst source: \(rows.winstSource)")
//     print("• Net income (total, injected): \(fmtDec(roundD(rows.niTotal, digits: d), digits: d))")
//     print("\(pad("Owner", 28)) \(pad("Begin", 14, .right)) \(pad("Stort", 14, .right)) \(pad("Onttrek", 14, .right)) \(pad("Winst", 14, .right)) \(pad("Eind", 14, .right))")

//     var tBegin = Decimal(0), tStort = Decimal(0), tOnt = Decimal(0), tWinst = Decimal(0), tEnd = Decimal(0)

//     for oid in rows.owners {
//         let nm = names[Int?(oid)] ?? "owner#\(oid)"
//         let b  = rows.beginByOwner[oid] ?? 0
//         let dlt = rows.deltas[oid]!
//         let e  = rows.endByOwner[oid] ?? (b + dlt.delta)

//         tBegin += b; tStort += dlt.stort; tOnt += dlt.onttrek; tWinst += dlt.winst; tEnd += e

//         print("\(pad(nm, 28)) " +
//               "\(pad(fmtDec(roundD(b, digits: d), digits: d), 14, .right)) " +
//               "\(pad(fmtDec(roundD(dlt.stort, digits: d), digits: d), 14, .right)) " +
//               "\(pad(fmtDec(roundD(dlt.onttrek, digits: d), digits: d), 14, .right)) " +
//               "\(pad(fmtDec(roundD(dlt.winst, digits: d), digits: d), 14, .right)) " +
//               "\(pad(fmtDec(roundD(e, digits: d), digits: d), 14, .right))")
//     }

//     print(String(repeating: "—", count: 28 + 1 + 14*5))
//     print("\(pad("TOTAL", 28)) " +
//           "\(pad(fmtDec(roundD(tBegin, digits: d), digits: d), 14, .right)) " +
//           "\(pad(fmtDec(roundD(tStort, digits: d), digits: d), 14, .right)) " +
//           "\(pad(fmtDec(roundD(tOnt,  digits: d), digits: d), 14, .right)) " +
//           "\(pad(fmtDec(roundD(tWinst,digits: d), digits: d), 14, .right)) " +
//           "\(pad(fmtDec(roundD(tEnd,  digits: d), digits: d), 14, .right))")

//     print("Check totals → Opening: \(fmtDec(roundD(rows.openingTotal, digits: d), digits: d)) | Closing: \(fmtDec(roundD(rows.closingTotal, digits: d), digits: d))")
//     print("Identity check: Begin + Stort − Onttrek + Winst = \(fmtDec(roundD(tBegin + tStort - tOnt + tWinst, digits: d), digits: d))")

//     // Allocation note
//     if !rows.allocationNote.isEmpty {
//         print("NI allocation (used): \(rows.winstSource)")
//         for oid in rows.owners {
//             let nm = names[Int?(oid)] ?? "owner#\(oid)"
//             let note = rows.allocationNote[oid] ?? (0, 0)
//             print("  • \(nm): \(fmtPct(note.percent, digits: d))  →  \(fmtDec(roundD(note.amount, digits: d), digits: d))")
//         }
//     }
// }

// // MARK: - Orchestrator

// /// Main entry: builds periods, anchors earliest begin, carries forward per-owner ends, and prints.
// public func runOwnerEquityRollforwardIB(
//     title: String = "IB equity rollforward (owner split, backsolved, no-guess)",
//     current cur: StatementBundle,
//     previous prv: StatementBundle?,                 // pass if you compiled with --compare
//     chart: CompiledChart,
//     entities: EntityStore,
//     asOfCurrent: Date,
//     asOfPrevious: Date?,                           // usually assembled.previous?.range.to
//     config cfg: EquityRollforwardConfig = EquityRollforwardConfig()
// ) throws {
//     // Build periods oldest → newest
//     var periods: [EquityPeriod] = []
//     if let p = prv, let pd = asOfPrevious { periods.append(.init(label: "Previous", bundle: p, asOf: pd)) }
//     periods.append(.init(label: "Current", bundle: cur, asOf: asOfCurrent))

//     guard !periods.isEmpty else {
//         printRollforwardHeader(title)
//         print("(no periods)")
//         return
//     }

//     // Prep maps
//     let maps = ChartMaps(chart: chart)

//     // Earliest begin map: owner-tagged opening if present; else BEGIN=0 per owner (no % guessing)
//     let earliest = periods[0]
//     var beginByOwner = try buildEarliestBeginMap(
//         earliest: earliest,
//         chart: chart,
//         cfg: cfg,
//         maps: maps,
//         probeOwnersWith: earliest.bundle,
//         asOf: earliest.asOf,
//         entities: entities
//     )

//     printRollforwardHeader(title)
//     if let eb = earliest.bundle.entity?.byAccount,
//        cfg.codes.beginCandidates.contains(where: { maps.idByCode[$0].flatMap { eb[$0] } != nil }) {
//         print("Earliest anchor: owner-tagged opening found on begin code — using posted per-owner BEGIN.")
//     } else {
//         print("Earliest anchor: no owner-tagged opening found — anchoring BEGIN = 0 per owner (no % guesses).")
//     }

//     // Walk periods, build rows, print, carry forward
//     for (i, p) in periods.enumerated() {
//         // Build movements
//         let (owners, deltas, alloc) = try buildOwnerDeltas(bundle: p.bundle, chart: chart, entities: entities, asOf: p.asOf, cfg: cfg, maps: maps)

//         // Compute end map
//         var endByOwner: [Int: Decimal] = [:]
//         for oid in owners {
//             let d = deltas[oid]!
//             endByOwner[oid] = (beginByOwner[oid] ?? 0) + d.delta
//         }

//         // Presentation totals
//         let (openTotal, closeTotal) = equityPresentationTotals(periodIndex: i, periods: periods, chart: chart, cfg: cfg, maps: maps)

//         // Allocation note (percent + amount per owner actually used this period)
//         var note: [Int: (Decimal, Decimal)] = [:]
//         for oid in owners {
//             let amt = alloc.usedAmounts[oid] ?? 0
//             let pct = alloc.usePosted
//                 ? ((alloc.niTotal == 0) ? 0 : (amt / alloc.niTotal))
//                 : (alloc.effectivePercents[oid] ?? 0)
//             note[oid] = (pct, amt)
//         }

//         // Compose period output
//         let rows = PeriodRollforward(
//             owners: owners,
//             beginByOwner: beginByOwner,
//             endByOwner: endByOwner,
//             deltas: deltas,
//             niTotal: alloc.niTotal,
//             winstSource: alloc.source,
//             allocationNote: note,
//             openingTotal: openTotal,
//             closingTotal: closeTotal
//         )

//         // Print table + note
//         printPeriodTable(label: p.label, rows: rows, entities: entities, cfg: cfg)

//         // Carry forward
//         beginByOwner = endByOwner
//     }

//     // Optional chain consistency check (End(prev) == Begin(next)) is tautological with our carry-forward.
// }
