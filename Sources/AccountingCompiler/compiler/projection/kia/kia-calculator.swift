import Accounting
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

            guard lowerOK && upperOK else {
                continue
            }

            // Declining bracket:
            // fixed deduction minus rate * excess above baseAmount
            if let fixed = bracket.fixedDeduction,
               let rate = bracket.rate,
               let base = bracket.baseAmount {
                let excess = qualifyingInvestmentTotal - base
                return fixed + (rate * excess)
            }

            // Flat fixed bracket
            if let fixed = bracket.fixedDeduction {
                return fixed
            }

            // Straight percentage bracket
            if let rate = bracket.rate {
                return qualifyingInvestmentTotal * rate
            }
        }

        return 0
    }
}
