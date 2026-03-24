import Foundation

public enum AssetsOverviewColumnProfile: String, Codable, Sendable {
    case intangibleFixedAssets
    case tangibleFixedAssets
    case financialFixedAssets
    case inventory
    case receivables
    case securities
    case liquidAssets
    case unclassified

    public var headers: [String] {
        switch self {
        case .intangibleFixedAssets:
            return [
                "Kosten van aanschaf of voortbrenging",
                "Boekwaarde begin boekjaar",
                "Boekwaarde einde boekjaar"
            ]

        case .tangibleFixedAssets:
            return [
                "Kosten van aanschaf of voortbrenging",
                "Boekwaarde begin boekjaar",
                "Boekwaarde einde boekjaar",
                "Restwaarde"
            ]

        case .financialFixedAssets:
            return [
                "Boekwaarde begin boekjaar",
                "Boekwaarde einde boekjaar"
            ]

        case .inventory:
            return [
                "Boekwaarde begin boekjaar",
                "Boekwaarde einde boekjaar"
            ]

        case .receivables:
            return [
                "Nominale waarde",
                "Boekwaarde begin boekjaar",
                "Boekwaarde einde boekjaar"
            ]

        case .securities:
            return [
                "Boekwaarde begin boekjaar",
                "Boekwaarde einde boekjaar"
            ]

        case .liquidAssets:
            return [
                "Boekwaarde begin boekjaar",
                "Boekwaarde einde boekjaar"
            ]

        case .unclassified:
            return [
                "Kosten / nominale waarde",
                "Boekwaarde begin boekjaar",
                "Boekwaarde einde boekjaar",
                "Restwaarde"
            ]
        }
    }

    public static func forSection(
        _ section: AssetsOverviewSection
    ) -> AssetsOverviewColumnProfile {
        switch section {
        case .intangibleFixedAssets:
            return .intangibleFixedAssets
        case .tangibleFixedAssets:
            return .tangibleFixedAssets
        case .financialFixedAssets:
            return .financialFixedAssets
        case .inventory:
            return .inventory
        case .receivables:
            return .receivables
        case .securities:
            return .securities
        case .liquidAssets:
            return .liquidAssets
        case .unclassified:
            return .unclassified
        }
    }
}
