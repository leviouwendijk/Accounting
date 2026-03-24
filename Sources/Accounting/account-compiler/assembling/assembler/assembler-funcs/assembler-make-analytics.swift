import Foundation

extension RGSAssembler {
    // // without fin ratios
    // @inline(__always)
    // public static func makeAnalytics(
    //     chart: CompiledChart,
    //     bundle: StatementBundle,
    //     omslag: OmslagMode
    // ) throws -> BundleAnalytics {
    //     let l2 = try RGSAssembler.makeL2Buckets(chart: chart, defaultEquityCode: "BEiv")
    //     let totals = try RGSAssembler.presentedTotalsByL2(chart: chart, bundle: bundle, buckets: l2, omslag: omslag)
    //     return BundleAnalytics(l2Buckets: l2, l2Totals: totals)
    // }

    @inline(__always)
    public static func makeAnalytics(
        chart: CompiledChart,
        bundle: StatementBundle,
        omslag: OmslagMode,
        netIncome: Decimal?
    ) throws -> BundleAnalytics {
        let l2 = try RGSAssembler.makeL2Buckets(
            chart: chart,
            defaultEquityCode: "BEiv"
        )

        let totals = try RGSAssembler.presentedTotalsByL2(
            chart: chart,
            bundle: bundle,
            buckets: l2,
            omslag: omslag
        )

        let ratios = FinancialRatiosBuilder.build(
            assets: totals.assets,
            equity: totals.equity,
            liabilities: totals.liabilities,
            netIncome: netIncome,
            omslag: omslag
        )

        return BundleAnalytics(
            l2Buckets: l2,
            l2Totals: totals,
            ratios: ratios
        )
    }
}
