import Foundation

public extension RGSAssembler {
    @discardableResult
    static func makeAndPrintAnalyticsDiagnostics(
        chart: CompiledChart,
        bundle: StatementBundle,
        businessEntity: BusinessEntity = .vof,
        omslag: OmslagMode = .apply,
        netIncome: Decimal? = nil,
        title: String = "Analytics diagnostics",
        includeNilBuckets: Bool = false
    ) throws -> BundleAnalytics {
        let analytics: BundleAnalytics

        if let existing = bundle.analytics {
            analytics = existing
        } else {
            var resolvedNetIncome = netIncome

            if resolvedNetIncome == nil {
                let maps = try RGSAssembler.makeMaps(from: chart)
                let resolver = CanonicalRootAmountResolver(
                    chart: chart,
                    bundle: bundle,
                    maps: maps,
                    omslag: omslag
                )

                resolvedNetIncome = resolver.shownAmount(
                    for: businessEntity.autoCloseTargets().netIncomeCode
                )
            }

            analytics = try makeAnalytics(
                chart: chart,
                bundle: bundle,
                businessEntity: businessEntity,
                omslag: omslag,
                netIncome: resolvedNetIncome
            )
        }

        printAnalyticsDiagnostics(
            analytics,
            title: title,
            includeNilBuckets: includeNilBuckets
        )

        return analytics
    }
}
