import Foundation

public enum FinancialRatiosBuilder {
    public static func build(
        assets: Decimal,
        equity: Decimal,
        liabilities: Decimal,
        netIncome: Decimal?,
        omslag: OmslagMode
    ) -> FinancialRatios? {
        let presentedNetIncome = netIncome.map {
            RGSAssembler.present(
                $0,
                direction: .credit,
                mode: omslag
            )
        }

        if assets == 0, equity == 0, liabilities == 0, presentedNetIncome == nil {
            return nil
        }

        return FinancialRatios(
            assets: assets,
            equity: equity,
            liabilities: liabilities,
            netIncome: presentedNetIncome,
            equityRatio: ratio(equity, over: assets),
            debtRatio: ratio(liabilities, over: assets),
            debtToEquity: ratio(liabilities, over: equity),
            equityMultiplier: ratio(assets, over: equity),
            returnOnAssets: presentedNetIncome.flatMap { ratio($0, over: assets) },
            returnOnEquity: presentedNetIncome.flatMap { ratio($0, over: equity) }
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
