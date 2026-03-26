import Foundation

public struct BundleAnalytics: Sendable {
    public let l2Buckets: L2Buckets
    public let l2Totals: PresentedBalanceTotals
    public let ratioInputs: FinancialRatioInputs?
    public let ratios: FinancialRatios?
    public let diagnostics: AnalyticsDiagnostics?

    public init(
        l2Buckets: L2Buckets,
        l2Totals: PresentedBalanceTotals,
        ratioInputs: FinancialRatioInputs? = nil,
        ratios: FinancialRatios? = nil,
        diagnostics: AnalyticsDiagnostics? = nil
    ) {
        self.l2Buckets = l2Buckets
        self.l2Totals = l2Totals
        self.ratioInputs = ratioInputs
        self.ratios = ratios
        self.diagnostics = diagnostics
    }
}
