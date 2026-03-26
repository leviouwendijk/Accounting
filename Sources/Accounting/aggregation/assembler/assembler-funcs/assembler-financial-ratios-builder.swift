import Foundation

public enum FinancialRatiosBuilder {
    public static func build(
        from inputs: FinancialRatioInputs
    ) -> FinancialRatios? {
        if inputs.assets == 0,
           inputs.equity == 0,
           inputs.liabilities == 0,
           inputs.netIncome == nil,
           inputs.netTurnover == nil,
           inputs.totalCurrentAssets == nil,
           inputs.totalCurrentLiabilities == nil {
            return nil
        }

        return FinancialRatios(
            assets: inputs.assets,
            equity: inputs.equity,
            liabilities: inputs.liabilities,
            netIncome: inputs.netIncome,
            equityRatio: ratio(inputs.equity, over: inputs.assets),
            debtRatio: ratio(inputs.liabilities, over: inputs.assets),
            debtToEquity: ratio(inputs.liabilities, over: inputs.equity),
            equityMultiplier: ratio(inputs.assets, over: inputs.equity),
            currentRatio: ratio(
                inputs.totalCurrentAssets,
                over: inputs.totalCurrentLiabilities
            ),
            quickRatio: ratio(
                inputs.quickAssets,
                over: inputs.totalCurrentLiabilities
            ),
            grossMargin: ratio(
                inputs.grossProfit,
                over: inputs.netTurnover
            ),
            operatingMargin: ratio(
                inputs.operatingResult,
                over: inputs.netTurnover
            ),
            netMargin: ratio(
                inputs.netIncome,
                over: inputs.netTurnover
            ),
            returnOnAssets: ratio(
                inputs.netIncome,
                over: inputs.assets
            ),
            returnOnEquity: ratio(
                inputs.netIncome,
                over: inputs.equity
            )
        )
    }

    @inline(__always)
    private static func ratio(
        _ numerator: Decimal?,
        over denominator: Decimal?
    ) -> Decimal? {
        guard let numerator, let denominator, denominator != 0 else {
            return nil
        }

        return numerator / denominator
    }

    @inline(__always)
    private static func ratio(
        _ numerator: Decimal,
        over denominator: Decimal
    ) -> Decimal? {
        guard denominator != 0 else {
            return nil
        }

        return numerator / denominator
    }
}
