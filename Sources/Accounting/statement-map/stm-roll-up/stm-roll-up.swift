// import Foundation

// public enum RollupMode {
//     case perAccount              // one row per account (label = account.label)
//     case byExactOmslag           // one row per omslag string (label picked from a representative account)
// }

// public struct DefaultFromAccounts {
//     public static func balanceDetail(from store: AccountStore,
//                                      mode: RollupMode = .perAccount,
//                                      materiality: Decimal = 0) -> StatementDef {
//         switch mode {
//         case .perAccount:
//             let rows: [StatementRowDef] = store.all.map { acc in
//                 // TEMP label: use code until you expose a preferred label on RGSNodeLabels
//                 let lbl = acc.codes.code
//                 let rgs = acc.codes.code
//                 return StatementRowDef(
//                     label: lbl.trimmingCharacters(in: .whitespacesAndNewlines),
//                     includeCodes: [rgs]
//                 )
//             }
//             return StatementDef(rows: rows)

//         case .byExactOmslag:
//             let groups = Dictionary(grouping: store.all) { n in
//                 n.omslagId.map(String.init) ?? "__NO_OMSLAG__"
//             }
//             let rows: [StatementRowDef] = groups.map { (omslag, accs) in
//                 let chosenLabel = accs.first.map { $0.codes.code } ?? (omslag == "__NO_OMSLAG__" ? "Other (no omslag)" : "Omslag \(omslag)")
//                 let codes = accs.map { $0.codes.code }
//                 return StatementRowDef(label: chosenLabel, includeCodes: codes)
//             }
//             return StatementDef(rows: rows)
//         }
//     }
// }
