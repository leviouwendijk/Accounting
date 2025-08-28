import Foundation

public struct LedgerIndex: Sendable {
    public var byAccount: [String: LedgerBucket] = [:]
    public var byAccountEntity: [String: [EntityKey: LedgerBucket]] = [:]
    // public var byMonthAccount: [YearMonth: [String: LedgerBucket]] = [:]
    // public var byMonthAccountEntity: [YearMonth: [String: [EntityKey: LedgerBucket]]] = [:]
}

// public enum IndexBuilder {
//     public static func build(from resolved: [ResolvedEntry]) -> LedgerIndex {
//         var idx = LedgerIndex()
//         for e in resolved {
//             let date = e.date.asBestEffortDate() // implement using your existing parsing; you already resolve dates elsewhere. :contentReference[oaicite:12]{index=12}
//             let ym = YearMonth(date)
//             for l in e.lines {
//                 let code = l.account.code     // String key — no optionals. :contentReference[oaicite:13]{index=13}
//                 // 1D
//                 idx.byAccount[code, default: .init()].add(dir: l.direction, amount: l.amount)
//                 // 2D
//                 var row = idx.byAccountEntity[code] ?? [:]
//                 row[l.entity, default: .init()].add(dir: l.direction, amount: l.amount)
//                 idx.byAccountEntity[code] = row
//                 // monthly 1D
//                 var m1 = idx.byMonthAccount[ym] ?? [:]
//                 m1[code, default: .init()].add(dir: l.direction, amount: l.amount)
//                 idx.byMonthAccount[ym] = m1
//                 // monthly 2D
//                 var m2 = idx.byMonthAccountEntity[ym] ?? [:]
//                 var m2row = m2[code] ?? [:]
//                 m2row[l.entity, default: .init()].add(dir: l.direction, amount: l.amount)
//                 m2[code] = m2row; idx.byMonthAccountEntity[ym] = m2
//             }
//         }
//         return idx
//     }
// }

public struct Ledger {
    /// Build both 1D (account) and 2D (account x entity) maps.
    public static func aggregate(
        resolved: [ResolvedEntry],
        captureProvenance: Bool = false
    ) -> LedgerIndex {
        var perAcc: [String: LedgerBucket] = [:]
        var perAccEnt: [String: [EntityKey: LedgerBucket]] = [:]

        for e in resolved {
            for l in e.lines {
                let code = l.account.code   // <- string code; no optional unwrap needed
                var b = perAcc[code] ?? .init()
                if l.direction == .debit { b.debit += l.amount } else { b.credit += l.amount }
                perAcc[code] = b

                var row = perAccEnt[code] ?? [:]
                var be = row[l.entity] ?? .init()
                if l.direction == .debit { be.debit += l.amount } else { be.credit += l.amount }
                row[l.entity] = be
                perAccEnt[code] = row
            }
        }

        return .init(byAccount: perAcc, byAccountEntity: perAccEnt)
    }

    public static func totalDebitsCredits(_ perAccount: [String: LedgerBucket]) -> (Decimal, Decimal) {
        var td: Decimal = 0, tc: Decimal = 0
        for (_, b) in perAccount { td += b.debit; tc += b.credit }
        return (td, tc)
    }
}
