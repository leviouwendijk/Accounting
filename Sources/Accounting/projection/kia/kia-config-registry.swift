import Foundation

public enum KIAConfigs {
    public static let nl_2025 = KIAConfig(
        countryCode: "NL",
        taxYear: 2025,
        minimumInvestmentTotal: 2_601,
        brackets: [
            KIABracket(
                lowerInclusive: 0,
                upperInclusive: 2_600,
                fixedDeduction: 0,
                rate: nil,
                baseAmount: nil
            ),
            KIABracket(
                lowerInclusive: 2_601,
                upperInclusive: 63_716,
                fixedDeduction: nil,
                rate: 0.28,
                baseAmount: nil
            ),
            KIABracket(
                lowerInclusive: 63_717,
                upperInclusive: 117_991,
                fixedDeduction: 17_841,
                rate: nil,
                baseAmount: nil
            ),
            KIABracket(
                lowerInclusive: 117_992,
                upperInclusive: 353_973,
                fixedDeduction: nil,
                rate: -0.0756,
                baseAmount: nil
            ),
            KIABracket(
                lowerInclusive: 353_974,
                upperInclusive: nil,
                fixedDeduction: 0,
                rate: nil,
                baseAmount: nil
            )
        ]
    )

    public static let nl_2026 = nl_2025

    public static func netherlands(year: Int) -> KIAConfig? {
        switch year {
        case 2025:
            return nl_2025
        case 2026:
            return nl_2026
        default:
            return nil
        }
    }
}
