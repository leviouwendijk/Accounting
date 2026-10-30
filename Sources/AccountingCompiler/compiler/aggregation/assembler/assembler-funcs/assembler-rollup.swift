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

    /// Mirror derived income along its presentation branch without adding it to
    /// the P&L root, which already contains the underlying revenue and expenses.
    /// The first ancestor without a parent is the rollup root, not a NI subtotal.
    static func addDerivedIncomePresentation(
        _ amount: Decimal,
        at id: Int,
        into totals: inout [Int: Decimal],
        parentById: [Int: Int]
    ) {
        guard amount != 0 else { return }
        var current = id
        totals[current, default: 0] += amount
        while let parent = parentById[current], parentById[parent] != nil {
            totals[parent, default: 0] += amount
            current = parent
        }
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
