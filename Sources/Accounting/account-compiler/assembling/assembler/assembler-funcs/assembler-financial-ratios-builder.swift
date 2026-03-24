import Foundation

public enum FinancialRatiosBuilder {
    public static func build(
        assets: Decimal,
        equity: Decimal,
        liabilities: Decimal,
        netIncome: Decimal?
    ) -> FinancialRatios? {
        if assets == 0, equity == 0, liabilities == 0, netIncome == nil {
            return nil
        }

        return FinancialRatios(
            assets: assets,
            equity: equity,
            liabilities: liabilities,
            netIncome: netIncome,
            equityRatio: ratio(equity, over: assets),
            debtRatio: ratio(liabilities, over: assets),
            debtToEquity: ratio(liabilities, over: equity),
            returnOnAssets: netIncome.flatMap { ratio($0, over: assets) },
            returnOnEquity: netIncome.flatMap { ratio($0, over: equity) }
        )
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
