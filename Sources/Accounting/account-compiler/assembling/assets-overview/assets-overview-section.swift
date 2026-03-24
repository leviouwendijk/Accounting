import Foundation

public enum AssetsOverviewSection: String, Codable, Sendable, CaseIterable {
    case intangibleFixedAssets
    case tangibleFixedAssets
    case financialFixedAssets
    case inventory
    case receivables
    case securities
    case liquidAssets
    case unclassified

    public var label: String {
        switch self {
        case .intangibleFixedAssets:
            return "Immateriële vaste activa"
        case .tangibleFixedAssets:
            return "Materiële vaste activa"
        case .financialFixedAssets:
            return "Financiële vaste activa"
        case .inventory:
            return "Voorraden"
        case .receivables:
            return "Vorderingen"
        case .securities:
            return "Effecten"
        case .liquidAssets:
            return "Liquide middelen"
        case .unclassified:
            return "Niet geclassificeerd"
        }
    }

    public var totalLabel: String {
        switch self {
        case .intangibleFixedAssets:
            return "Totaal immateriële vaste activa"
        case .tangibleFixedAssets:
            return "Totaal materiële vaste activa"
        case .financialFixedAssets:
            return "Totaal financiële vaste activa"
        case .inventory:
            return "Totaal voorraden"
        case .receivables:
            return "Totaal vorderingen"
        case .securities:
            return "Totaal effecten"
        case .liquidAssets:
            return "Totaal liquide middelen"
        case .unclassified:
            return "Totaal niet geclassificeerd"
        }
    }

    public var sortOrder: Int {
        switch self {
        case .intangibleFixedAssets:
            return 0
        case .tangibleFixedAssets:
            return 1
        case .financialFixedAssets:
            return 2
        case .inventory:
            return 3
        case .receivables:
            return 4
        case .securities:
            return 5
        case .liquidAssets:
            return 6
        case .unclassified:
            return 99
        }
    }
}
