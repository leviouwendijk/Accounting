// import Foundation

// internal struct LineSpec {
//     let account: String?
//     let entity: String?
//     let dir: String?        // "dr" or "cr"
//     let amount: Decimal?
//     let invAdd: Decimal?
//     let invRem: Decimal?
// }

// public extension LegacyJournalEntry {
//     func prepareInventoryBlock(add: Decimal?, remove: Decimal?) -> String? {
//         if let q = add {
//             return """
//             inventory {
//                 mutation = add
//                 count = \(decString(q, scale: 0))
//             }
//             """
//         }
//         if let q = remove {
//             return """
//             inventory {
//                 mutation = remove
//                 count = \(decString(q, scale: 0))
//             }
//             """
//         }
//         return nil
//     }

//     func buildLineSpec() -> [LineSpec] {
//         return [
//             .init(account: dr1Account, entity: dr1Entity,
//                   dir: dr1Amount != nil ? "dr" : nil, amount: dr1Amount,
//                   invAdd: dr1InventoryIncrease, invRem: dr1InventoryDecrease),
//             .init(account: dr2Account, entity: dr2Entity,
//                   dir: dr2Amount != nil ? "dr" : nil, amount: dr2Amount,
//                   invAdd: dr2InventoryIncrease, invRem: dr2InventoryDecrease),
//             .init(account: cr1Account, entity: cr1Entity,
//                   dir: cr1Amount != nil ? "cr" : nil, amount: cr1Amount,
//                   invAdd: cr1InventoryIncrease, invRem: cr1InventoryDecrease),
//             .init(account: cr2Account, entity: cr2Entity,
//                   dir: cr2Amount != nil ? "cr" : nil, amount: cr2Amount,
//                   invAdd: cr2InventoryIncrease, invRem: cr2InventoryDecrease),
//         ]
//     }
// }
