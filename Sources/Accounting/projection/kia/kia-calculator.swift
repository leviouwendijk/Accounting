import Foundation

public enum KIACalculator {
    public static func compute(
        qualifyingInvestmentTotal: Decimal,
        config: KIAConfig
    ) -> Decimal {
        guard qualifyingInvestmentTotal >= config.minimumInvestmentTotal else {
            return 0
        }

        for bracket in config.brackets {
            let lowerOK = qualifyingInvestmentTotal >= bracket.lowerInclusive
            let upperOK = bracket.upperInclusive.map { qualifyingInvestmentTotal <= $0 } ?? true

            guard lowerOK && upperOK else { continue }

            if let fixed = bracket.fixedDeduction {
                return fixed
            }

            if let rate = bracket.rate {
                let base = bracket.baseAmount ?? qualifyingInvestmentTotal
                return base * rate
            }
        }

        return 0
    }
}
