// import Foundation

// public struct DefaultSummary {
//     public static func balanceSections(from store: AccountStore, materiality: Decimal = 0) -> StatementDef {
//         // crude split by natural side (works as a default) + omslag-based selection
//         let assetOms   = Set(store.all.filter { $0.direction == .debit  }.compactMap { $0.omslagId })
//         let liabEqOms  = Set(store.all.filter { $0.direction == .credit }.compactMap { $0.omslagId })

//         let assets = StatementRowDef(
//             id: .init(raw: "assets"), label: "Assets", kind: .balance,
//             materialityThreshold: materiality,
//             rgs: [.init(includeCodes: nil, includePrefixes: nil, includeLevel: nil,
//                         includeOmslagPrefixes: Array(assetOms), filterDirection: nil)]
//         )
//         let equity = StatementRowDef(
//             id: .init(raw: "equity"), label: "Equity", kind: .balance,
//             materialityThreshold: 0,
//             rgs: [.init(includeCodes: nil, includePrefixes: nil, includeLevel: nil,
//                         includeOmslagPrefixes: Array(liabEqOms), filterDirection: nil)]
//         )
//         // If you want Liabilities separate from Equity, add a rule set that targets liability omslag prefixes only.
//         // For now, this keeps your existing “equity injection” step to make the identity hold.

//         return StatementDef(name: "Balance – Sections (derived)", kind: .balance, rows: [assets, equity])
//     }

//     public static func incomeSections(from store: AccountStore, materiality: Decimal = 0) -> StatementDef {
//         // naive default: direction credit → Revenue, direction debit → Expenses (works for your current sample)
//         let revenueRGS = Set(store.all.filter { $0.direction == .credit }.map { $0.codes.code })
//         let expenseRGS = Set(store.all.filter { $0.direction == .debit  }.map { $0.codes.code })

//         let revenue = StatementRowDef(
//             id: .init(raw: "revenue"), label: "Revenue", kind: .income,
//             materialityThreshold: materiality,
//             rgs: [.init(includeCodes: Array(revenueRGS), includePrefixes: nil, includeLevel: nil,
//                         includeOmslagPrefixes: nil, filterDirection: nil)]
//         )
//         let expenses = StatementRowDef(
//             id: .init(raw: "expenses"), label: "COGS/Expenses", kind: .income,
//             materialityThreshold: materiality,
//             rgs: [.init(includeCodes: Array(expenseRGS), includePrefixes: nil, includeLevel: nil,
//                         includeOmslagPrefixes: nil, filterDirection: nil)]
//         )

//         return StatementDef(name: "Income – Sections (derived)", kind: .income, rows: [revenue, expenses])
//     }
// }
