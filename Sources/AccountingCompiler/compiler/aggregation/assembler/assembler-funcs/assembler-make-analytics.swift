import Accounting
import Foundation

extension RGSAssembler {
    @inline(__always)
    public static func makeAnalytics(
        chart: CompiledChart,
        bundle: StatementBundle,
        businessEntity: BusinessEntity = .vof,
        omslag: OmslagMode,
        netIncome: Decimal?
    ) throws -> BundleAnalytics {
        let maps = try RGSAssembler.makeMaps(from: chart)

        let l2 = try RGSAssembler.makeL2Buckets(
            chart: chart,
            defaultEquityCode: businessEntity
                .periodOpeningRouting
                .equityAnchorCode
        )

        let totals = try RGSAssembler.presentedTotalsByL2(
            chart: chart,
            bundle: bundle,
            buckets: l2,
            omslag: omslag
        )

        let roots = businessEntity.analyticsRoots

        let resolver = CanonicalRootAmountResolver(
            chart: chart,
            bundle: bundle,
            maps: maps,
            omslag: omslag
        )

        let presentedNetIncome = netIncome.map {
            RGSAssembler.present(
                $0,
                direction: .credit,
                mode: omslag
            )
        }

        let netTurnoverMatches = resolver.shownAmountsByCode(
            for: [roots.netTurnoverCode]
        )
        let costOfRevenueMatches = resolver.shownAmountsByCode(
            for: [roots.costOfRevenueCode]
        )
        let operatingExpensesMatches = resolver.shownAmountsByCode(
            for: [roots.operatingExpensesCode]
        )
        let depreciationExpensesMatches = resolver.shownAmountsByCode(
            for: [roots.depreciationExpensesCode]
        )
        let financialResultMatches = resolver.shownAmountsByCode(
            for: [roots.financialResultCode]
        )

        let liquidAssetsMatches = resolver.shownAmountsByCode(
            for: roots.liquidAssetsCodes
        )
        let shortTermSecuritiesMatches = resolver.shownAmountsByCode(
            for: roots.shortTermSecuritiesCodes
        )
        let accruedCurrentAssetsMatches = resolver.shownAmountsByCode(
            for: roots.accruedCurrentAssetsCodes
        )
        let inventoryMatches = resolver.shownAmountsByCode(
            for: roots.inventoryCodes
        )
        let workInProgressMatches = resolver.shownAmountsByCode(
            for: roots.workInProgressCodes
        )
        let accruedCurrentLiabilitiesMatches = resolver.shownAmountsByCode(
            for: roots.accruedCurrentLiabilitiesCodes
        )

        let detailedReceivablesCodes =
            roots.tradeReceivablesCodes
            + roots.otherReceivablesCodes

        let detailedReceivablesMatches = resolver.shownAmountsByCode(
            for: detailedReceivablesCodes
        )
        let broadReceivablesMatches = resolver.shownAmountsByCode(
            for: roots.receivablesCodes
        )

        let detailedReceivables = sumMatches(
            detailedReceivablesMatches
        )
        let broadReceivables = sumMatches(
            broadReceivablesMatches
        )
        let usedReceivablesFallback =
            detailedReceivables == nil
            && broadReceivables != nil
        let resolvedReceivables =
            detailedReceivables
            ?? broadReceivables

        let detailedCurrentLiabilitiesCodes =
            roots.tradeCreditorsCodes
            + roots.taxAndSocialChargesCodes
            + roots.otherCurrentLiabilitiesCodes
            + roots.workInProgressLiabilityCodes

        let detailedCurrentLiabilitiesMatches = resolver.shownAmountsByCode(
            for: detailedCurrentLiabilitiesCodes
        )
        let broadCurrentLiabilitiesMatches = resolver.shownAmountsByCode(
            for: roots.currentLiabilitiesCodes
        )

        let detailedCurrentLiabilities = sumMatches(
            detailedCurrentLiabilitiesMatches
        )
        let broadCurrentLiabilities = sumMatches(
            broadCurrentLiabilitiesMatches
        )
        let usedCurrentLiabilitiesFallback =
            detailedCurrentLiabilities == nil
            && broadCurrentLiabilities != nil
        let resolvedCurrentLiabilities =
            detailedCurrentLiabilities
            ?? broadCurrentLiabilities

        let inputs = FinancialRatioInputs(
            assets: totals.assets,
            equity: totals.equity,
            liabilities: totals.liabilities,
            netTurnover: sumMatches(netTurnoverMatches),
            costOfRevenue: sumMatches(costOfRevenueMatches),
            operatingExpenses: sumMatches(operatingExpensesMatches),
            depreciationExpenses: sumMatches(depreciationExpensesMatches),
            financialResult: sumMatches(financialResultMatches),
            netIncome: presentedNetIncome,
            liquidAssets: sumMatches(liquidAssetsMatches),
            shortTermSecurities: sumMatches(shortTermSecuritiesMatches),
            receivables: resolvedReceivables,
            accruedCurrentAssets: sumMatches(accruedCurrentAssetsMatches),
            inventory: sumMatches(inventoryMatches),
            workInProgress: sumMatches(workInProgressMatches),
            currentLiabilities: resolvedCurrentLiabilities,
            accruedCurrentLiabilities: sumMatches(accruedCurrentLiabilitiesMatches)
        )

        let ratios = FinancialRatiosBuilder.build(
            from: inputs
        )

        let diagnostics = AnalyticsDiagnostics(
            buckets: [
                .init(
                    key: "netTurnover",
                    label: "Net turnover",
                    codes: [roots.netTurnoverCode],
                    resolvedCodes: netTurnoverMatches.map(\.code),
                    amount: inputs.netTurnover
                ),
                .init(
                    key: "costOfRevenue",
                    label: "Cost of revenue",
                    codes: [roots.costOfRevenueCode],
                    resolvedCodes: costOfRevenueMatches.map(\.code),
                    amount: inputs.costOfRevenue
                ),
                .init(
                    key: "operatingExpenses",
                    label: "Operating expenses",
                    codes: [roots.operatingExpensesCode],
                    resolvedCodes: operatingExpensesMatches.map(\.code),
                    amount: inputs.operatingExpenses
                ),
                .init(
                    key: "depreciationExpenses",
                    label: "Depreciation expenses",
                    codes: [roots.depreciationExpensesCode],
                    resolvedCodes: depreciationExpensesMatches.map(\.code),
                    amount: inputs.depreciationExpenses
                ),
                .init(
                    key: "financialResult",
                    label: "Financial result",
                    codes: [roots.financialResultCode],
                    resolvedCodes: financialResultMatches.map(\.code),
                    amount: inputs.financialResult
                ),
                .init(
                    key: "liquidAssets",
                    label: "Liquid assets",
                    codes: roots.liquidAssetsCodes,
                    resolvedCodes: liquidAssetsMatches.map(\.code),
                    amount: inputs.liquidAssets
                ),
                .init(
                    key: "shortTermSecurities",
                    label: "Short-term securities",
                    codes: roots.shortTermSecuritiesCodes,
                    resolvedCodes: shortTermSecuritiesMatches.map(\.code),
                    amount: inputs.shortTermSecurities
                ),
                .init(
                    key: "receivables",
                    label: "Receivables",
                    codes: detailedReceivablesCodes,
                    resolvedCodes: detailedReceivablesMatches.map(\.code),
                    fallbackCodes: roots.receivablesCodes,
                    resolvedFallbackCodes: broadReceivablesMatches.map(\.code),
                    usedFallback: usedReceivablesFallback,
                    amount: inputs.receivables
                ),
                .init(
                    key: "accruedCurrentAssets",
                    label: "Accrued current assets",
                    codes: roots.accruedCurrentAssetsCodes,
                    resolvedCodes: accruedCurrentAssetsMatches.map(\.code),
                    amount: inputs.accruedCurrentAssets
                ),
                .init(
                    key: "inventory",
                    label: "Inventory",
                    codes: roots.inventoryCodes,
                    resolvedCodes: inventoryMatches.map(\.code),
                    amount: inputs.inventory
                ),
                .init(
                    key: "workInProgress",
                    label: "Work in progress",
                    codes: roots.workInProgressCodes,
                    resolvedCodes: workInProgressMatches.map(\.code),
                    amount: inputs.workInProgress
                ),
                .init(
                    key: "currentLiabilities",
                    label: "Current liabilities",
                    codes: detailedCurrentLiabilitiesCodes,
                    resolvedCodes: detailedCurrentLiabilitiesMatches.map(\.code),
                    fallbackCodes: roots.currentLiabilitiesCodes,
                    resolvedFallbackCodes: broadCurrentLiabilitiesMatches.map(\.code),
                    usedFallback: usedCurrentLiabilitiesFallback,
                    amount: inputs.currentLiabilities
                ),
                .init(
                    key: "accruedCurrentLiabilities",
                    label: "Accrued current liabilities",
                    codes: roots.accruedCurrentLiabilitiesCodes,
                    resolvedCodes: accruedCurrentLiabilitiesMatches.map(\.code),
                    amount: inputs.accruedCurrentLiabilities
                ),
            ],
            derived: [
                .init(
                    key: "grossProfit",
                    label: "Gross profit",
                    formula: "netTurnover - costOfRevenue",
                    amount: inputs.grossProfit
                ),
                .init(
                    key: "totalBusinessExpenses",
                    label: "Total business expenses",
                    formula: "operatingExpenses + depreciationExpenses",
                    amount: inputs.totalBusinessExpenses
                ),
                .init(
                    key: "operatingResult",
                    label: "Operating result",
                    formula: "grossProfit - totalBusinessExpenses",
                    amount: inputs.operatingResult
                ),
                .init(
                    key: "totalCurrentAssets",
                    label: "Total current assets",
                    formula: "liquidAssets + shortTermSecurities + receivables + accruedCurrentAssets + inventory + workInProgress",
                    amount: inputs.totalCurrentAssets
                ),
                .init(
                    key: "quickAssets",
                    label: "Quick assets",
                    formula: "totalCurrentAssets - inventory - workInProgress",
                    amount: inputs.quickAssets
                ),
                .init(
                    key: "totalCurrentLiabilities",
                    label: "Total current liabilities",
                    formula: "currentLiabilities + accruedCurrentLiabilities",
                    amount: inputs.totalCurrentLiabilities
                ),
            ]
        )

        return BundleAnalytics(
            l2Buckets: l2,
            l2Totals: totals,
            ratioInputs: inputs,
            ratios: ratios,
            diagnostics: diagnostics
        )
    }

    @inline(__always)
    private static func sumAvailable(
        _ values: Decimal?...
    ) -> Decimal? {
        let present = values.compactMap { $0 }

        guard !present.isEmpty else {
            return nil
        }

        return present.reduce(0, +)
    }

    @inline(__always)
    private static func sumMatches(
        _ matches: [(code: String, amount: Decimal)]
    ) -> Decimal? {
        guard !matches.isEmpty else {
            return nil
        }

        return matches.reduce(0) { partial, next in
            partial + next.amount
        }
    }
}

    // @inline(__always)
    // public static func makeAnalytics(
    //     chart: CompiledChart,
    //     bundle: StatementBundle,
    //     omslag: OmslagMode,
    //     netIncome: Decimal?
    // ) throws -> BundleAnalytics {
    //     let l2 = try RGSAssembler.makeL2Buckets(
    //         chart: chart,
    //         defaultEquityCode: "BEiv"
    //     )

    //     let totals = try RGSAssembler.presentedTotalsByL2(
    //         chart: chart,
    //         bundle: bundle,
    //         buckets: l2,
    //         omslag: omslag
    //     )

    //     let ratios = FinancialRatiosBuilder.build(
    //         assets: totals.assets,
    //         equity: totals.equity,
    //         liabilities: totals.liabilities,
    //         netIncome: netIncome,
    //         omslag: omslag
    //     )

    //     return BundleAnalytics(
    //         l2Buckets: l2,
    //         l2Totals: totals,
    //         ratios: ratios
    //     )
    // }
