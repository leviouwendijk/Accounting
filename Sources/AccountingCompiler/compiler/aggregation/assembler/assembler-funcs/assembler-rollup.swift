import Accounting
import Foundation

extension RGSAssembler {
    public static func rollupAmounts(
        _ seed: [Int: Decimal],
        parentById: [Int: Int]
    ) -> [Int: Decimal] {
        var totals = seed
        for (leaf, amt) in seed where amt != 0 {
            var cur = leaf
            while let p = parentById[cur] {
                totals[p, default: 0] += amt
                cur = p
            }
        }
        return totals
    }

    @inlinable
    public static func rollupByAccountPreservingEntity(
        _ seed: [AccEntKey: Decimal],
        parentById: [Int: Int]
    ) -> [AccEntKey: Decimal] {
        var totals = seed
        @inline(__always) func push(_ aid: Int, _ eid: Int?, _ v: Decimal) {
            guard v != 0 else { return }
            totals[AccEntKey(aid, eid), default: 0] += v
        }
        for (k, v) in seed where v != 0 {
            var a = k.accountId
            while let p = parentById[a] {
                push(p, k.entityId, v)    // same entity, parent account
                a = p
            }
        }
        return totals
    }
}
