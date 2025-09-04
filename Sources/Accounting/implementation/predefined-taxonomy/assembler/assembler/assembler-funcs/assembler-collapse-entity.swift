import Foundation

extension RGSAssembler {
    @inlinable
    public static func collapseEntityDimension(_ x: [AccEntKey: Decimal]) -> [Int: Decimal] {
        var out: [Int: Decimal] = [:]
        for (k, v) in x where v != 0 {
            out[k.accountId, default: 0] += v
        }
        return out
    }
}
