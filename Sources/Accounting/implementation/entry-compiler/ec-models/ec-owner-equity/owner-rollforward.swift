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
