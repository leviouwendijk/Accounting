import Foundation

public struct BundleAnalytics: Sendable {
    public let l2Buckets: L2Buckets
    public let l2Totals: PresentedBalanceTotals
    public let ratios: FinancialRatios?

    public init(
        l2Buckets: L2Buckets,
        l2Totals: PresentedBalanceTotals,
        ratios: FinancialRatios? = nil
    ) {
        self.l2Buckets = l2Buckets
        self.l2Totals = l2Totals
        self.ratios = ratios
    }
}
