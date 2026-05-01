import Accounting
import Foundation

extension RGSAssembler {
    public static func seedLeafs(
        from trial: [TrialBalanceRow],
        using index: RGSIndex
    ) -> [Int: Decimal] {
        var byId: [Int: Decimal] = [:]
        for row in trial {
            if let id = index.byIdentifier[row.accountCode] {
                byId[id, default: 0] += row.net
            }
        }
        return byId
    }

    // If you already have `row.entityId` on TrialBalanceRow:
    public static func seedLeafsAE(
        from trial: [TrialBalanceRow],
        using index: RGSIndex,
        entityId: (TrialBalanceRow) -> Int?
    ) -> [AccEntKey: Decimal] {
        var by: [AccEntKey: Decimal] = [:]
        for row in trial {
            guard let accId = index.byIdentifier[row.accountCode] else { continue }
            let eid = entityId(row)
            let key = AccEntKey(accId, eid)
            by[key, default: 0] += row.net
        }
        return by
    }

    // Fallback (no entity on rows yet): everything goes in `nil` bucket
    public static func seedLeafsAE(
        from trial: [TrialBalanceRow],
        using index: RGSIndex
    ) -> [AccEntKey: Decimal] {
        var by: [AccEntKey: Decimal] = [:]
        for row in trial {
            guard let accId = index.byIdentifier[row.accountCode] else { continue }
            by[AccEntKey(accId, nil), default: 0] += row.net
        }
        return by
    }
}
