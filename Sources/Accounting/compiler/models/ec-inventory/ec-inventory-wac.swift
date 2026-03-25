// future implementation

// import Foundation

// public struct WACEvent: Sendable, Codable {
//     public let date: Date
//     public let entryID: Int?
//     public let account: AccountKey
//     public let entity: EntityKey
//     public let mutation: String         // "add" or "remove"
//     public let count: Decimal
//     public let ledgerDelta: Decimal     // +debit / -credit for the asset account
//     public let expectedCOGS: Decimal?   // only on removals
//     public let avgBefore: Decimal
//     public let avgAfter: Decimal
//     public let qohBefore: Decimal
//     public let qohAfter: Decimal
//     public let basisBefore: Decimal
//     public let basisAfter: Decimal
//     public let note: String?
// }

// public struct WACSnapshot: Sendable, Codable {
//     public let entity: EntityKey
//     public let subtreeRoot: AccountKey
//     public let quantityOnHand: Decimal
//     public let averageCost: Decimal
//     public let costBasis: Decimal
//     public let lastDate: Date?
//     public let events: [WACEvent]   // optional audit trail (can be heavy)
// }

// private struct WACState {
//     var qoh: Decimal = 0     // quantity on hand
//     var basis: Decimal = 0   // total carrying amount of the inventory
//     var avg: Decimal { qoh == 0 ? 0 : (basis / qoh) }
//     var lastDate: Date?
//     var events: [WACEvent] = []
// }

// public extension Array where Element == ResolvedEntry {
//     /// Compute Moving Weighted-Average Cost per entity, restricted to a chosen account subtree.
//     ///
//     /// - includeAccount:  which accounts to consider (e.g., subtree predicate)
//     /// - includeEntity:   optional entity filter
//     /// - dateOf:          how to get `Date` from `ResolvedEntry` (match your depreciation audit style)
//     /// - recordEvents:    include detailed event trail
//     func weightedAverageCost(
//         includeAccount: @escaping (AccountKey) -> Bool,
//         includeEntity: (EntityKey) -> Bool = { _ in true },
//         dateOf: (ResolvedEntry) -> Date,
//         recordEvents: Bool = true
//     ) -> [EntityKey: WACSnapshot] {

//         // 1) Linearize chronologically (stable within same-date by input order)
//         let sorted = self.sorted { dateOf($0) < dateOf($1) }

//         // 2) Per-entity moving WAC state
//         var state: [EntityKey: WACState] = [:]

//         // Helper to convert debit/credit → signed ledger delta for basis
//         @inline(__always)
//         func signedLedgerDelta(direction: Direction, amount: Decimal) -> Decimal {
//             return direction == .debit ? amount : -amount
//         }

//         for e in sorted {
//             let d = dateOf(e)
//             for l in e.lines {
//                 // Only look at selected account subtree + entities
//                 guard includeAccount(l.account), includeEntity(l.entity) else { continue }
//                 guard let adj = l.adjustment else { continue }          // only lines carrying an inventory adjustment
//                 // adj.mutation = .addition / .reduction (from parser)
//                 // adj.count is Decimal
//                 let ledgerDelta = signedLedgerDelta(direction: l.direction, amount: l.amount)

//                 var s = state[l.entity, default: .init()]
//                 let beforeAvg = s.avg
//                 let beforeQ  = s.qoh
//                 let beforeB  = s.basis

//                 switch adj.mutation {
//                 case .addition: // purchase / capitalization into inventory
//                     // Move basis by ledger delta, increase QOH by count
//                     s.basis += ledgerDelta
//                     s.qoh   += adj.count
//                     s.lastDate = d

//                     if recordEvents {
//                         s.events.append(.init(
//                             date: d,
//                             entryID: e.id,
//                             account: l.account,
//                             entity: l.entity,
//                             mutation: "add",
//                             count: adj.count,
//                             ledgerDelta: ledgerDelta,
//                             expectedCOGS: nil,
//                             avgBefore: beforeAvg,
//                             avgAfter: s.avg,
//                             qohBefore: beforeQ,
//                             qohAfter: s.qoh,
//                             basisBefore: beforeB,
//                             basisAfter: s.basis,
//                             note: nil
//                         ))
//                     }

//                 case .reduction: // sale / issue out of inventory (COGS at current avg)
//                     let removeQty = adj.count
//                     let usedAvg   = beforeAvg
//                     let expectedCOGS = (removeQty * usedAvg)

//                     // Decrease basis by expected COGS, decrease QOH by removeQty.
//                     // We purposely do NOT trust ledger amount here to recalc avg; we audit it instead.
//                     s.basis -= expectedCOGS
//                     s.qoh   -= removeQty
//                     s.lastDate = d

//                     if recordEvents {
//                         let note: String? = {
//                             // If the credit posted on the asset account differed from expectedCOGS, note mismatch.
//                             let postedCOGSDiff = ledgerDelta - (-expectedCOGS) // ledger should be negative for credit
//                             return postedCOGSDiff == 0 ? nil
//                                 : "Asset-credit vs expected COGS mismatch: Δ=\(postedCOGSDiff)"
//                         }()

//                         s.events.append(.init(
//                             date: d,
//                             entryID: e.id,
//                             account: l.account,
//                             entity: l.entity,
//                             mutation: "remove",
//                             count: removeQty,
//                             ledgerDelta: ledgerDelta,
//                             expectedCOGS: expectedCOGS,
//                             avgBefore: beforeAvg,
//                             avgAfter: s.avg,
//                             qohBefore: beforeQ,
//                             qohAfter: s.qoh,
//                             basisBefore: beforeB,
//                             basisAfter: s.basis,
//                             note: note
//                         ))
//                     }
//                 }

//                 state[l.entity] = s
//             }
//         }

//         // 3) Project to snapshots
//         // The subtree root is not known inside the reducer; the caller supplies the predicate.
//         // For output, we can’t infer a single root key; capture a placeholder and let the wrapper fill it.
//         return state.mapValues { s in
//             WACSnapshot(
//                 entity: EntityKey("__filled_by_wrapper__"),
//                 subtreeRoot: AccountKey("__filled_by_wrapper__"),
//                 quantityOnHand: s.qoh,
//                 averageCost: s.avg,
//                 costBasis: s.basis,
//                 lastDate: s.lastDate,
//                 events: s.events
//             )
//         }
//     }
// }
