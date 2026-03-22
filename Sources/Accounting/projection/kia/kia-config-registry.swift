import Foundation

public enum KIAConfigs {
    // // 2022:
    // // I could not find the archived Belastingdienst year page directly anymore.
    // // These figures were corroborated from multiple Dutch secondary sources.
    // public static let nl_2022 = KIAConfig(
    //     countryCode: "NL",
    //     taxYear: 2022,
    //     minimumInvestmentTotal: 2_401,
    //     minimumAssetAmount: 450,
    //     brackets: [
    //         KIABracket(
    //             lowerInclusive: 0,
    //             upperInclusive: 2_400,
    //             fixedDeduction: 0,
    //             rate: nil,
    //             baseAmount: nil
    //         ),
    //         KIABracket(
    //             lowerInclusive: 2_401,
    //             upperInclusive: 59_939,
    //             fixedDeduction: nil,
    //             rate: 0.28,
    //             baseAmount: nil
    //         ),
    //         KIABracket(
    //             lowerInclusive: 59_940,
    //             upperInclusive: 110_998,
    //             fixedDeduction: 16_784,
    //             rate: nil,
    //             baseAmount: nil
    //         ),
    //         KIABracket(
    //             lowerInclusive: 110_999,
    //             upperInclusive: 332_994,
    //             fixedDeduction: 16_784,
    //             rate: -0.0756,
    //             baseAmount: 110_998
    //         ),
    //         KIABracket(
    //             lowerInclusive: 332_995,
    //             upperInclusive: nil,
    //             fixedDeduction: 0,
    //             rate: nil,
    //             baseAmount: nil
    //         )
    //     ]
    // )

    public static let nl_2023 = KIAConfig(
        countryCode: "NL",
        taxYear: 2023,
        minimumInvestmentTotal: 2_601,
        minimumAssetAmount: 450,
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
                fixedDeduction: 17_841,
                rate: -0.0756,
                baseAmount: 117_991
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

    public static let nl_2024 = KIAConfig(
        countryCode: "NL",
        taxYear: 2024,
        minimumInvestmentTotal: 2_801,
        minimumAssetAmount: 450,
        brackets: [
            KIABracket(
                lowerInclusive: 0,
                upperInclusive: 2_800,
                fixedDeduction: 0,
                rate: nil,
                baseAmount: nil
            ),
            KIABracket(
                lowerInclusive: 2_801,
                upperInclusive: 69_765,
                fixedDeduction: nil,
                rate: 0.28,
                baseAmount: nil
            ),
            KIABracket(
                lowerInclusive: 69_766,
                upperInclusive: 129_194,
                fixedDeduction: 19_535,
                rate: nil,
                baseAmount: nil
            ),
            KIABracket(
                lowerInclusive: 129_195,
                upperInclusive: 387_580,
                fixedDeduction: 19_535,
                rate: -0.0756,
                baseAmount: 129_194
            ),
            KIABracket(
                lowerInclusive: 387_581,
                upperInclusive: nil,
                fixedDeduction: 0,
                rate: nil,
                baseAmount: nil
            )
        ]
    )

    public static let nl_2025 = KIAConfig(
        countryCode: "NL",
        taxYear: 2025,
        minimumInvestmentTotal: 2_901,
        minimumAssetAmount: 450,
        brackets: [
            KIABracket(
                lowerInclusive: 0,
                upperInclusive: 2_900,
                fixedDeduction: 0,
                rate: nil,
                baseAmount: nil
            ),
            KIABracket(
                lowerInclusive: 2_901,
                upperInclusive: 70_602,
                fixedDeduction: nil,
                rate: 0.28,
                baseAmount: nil
            ),
            KIABracket(
                lowerInclusive: 70_603,
                upperInclusive: 130_744,
                fixedDeduction: 19_769,
                rate: nil,
                baseAmount: nil
            ),
            KIABracket(
                lowerInclusive: 130_745,
                upperInclusive: 392_230,
                fixedDeduction: 19_769,
                rate: -0.0756,
                baseAmount: 130_744
            ),
            KIABracket(
                lowerInclusive: 392_231,
                upperInclusive: nil,
                fixedDeduction: 0,
                rate: nil,
                baseAmount: nil
            )
        ]
    )

    public static let nl_2026 = KIAConfig(
        countryCode: "NL",
        taxYear: 2026,
        minimumInvestmentTotal: 2_901,
        minimumAssetAmount: 450,
        brackets: [
            KIABracket(
                lowerInclusive: 0,
                upperInclusive: 2_900,
                fixedDeduction: 0,
                rate: nil,
                baseAmount: nil
            ),
            KIABracket(
                lowerInclusive: 2_901,
                upperInclusive: 71_683,
                fixedDeduction: nil,
                rate: 0.28,
                baseAmount: nil
            ),
            KIABracket(
                lowerInclusive: 71_684,
                upperInclusive: 132_746,
                fixedDeduction: 20_072,
                rate: nil,
                baseAmount: nil
            ),
            KIABracket(
                lowerInclusive: 132_747,
                upperInclusive: 398_236,
                fixedDeduction: 20_072,
                rate: -0.0756,
                baseAmount: 132_746
            ),
            KIABracket(
                lowerInclusive: 398_237,
                upperInclusive: nil,
                fixedDeduction: 0,
                rate: nil,
                baseAmount: nil
            )
        ]
    )

    public static func netherlands(year: Int) -> KIAConfig? {
        switch year {
        case 2023:
            return nl_2023
        case 2024:
            return nl_2024
        case 2025:
            return nl_2025
        case 2026:
            return nl_2026
        default:
            return nil
        }
    }
}
