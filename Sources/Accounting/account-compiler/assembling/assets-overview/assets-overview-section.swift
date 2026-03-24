import Foundation

public enum AssetsOverviewSection: String, Codable, Sendable, CaseIterable {
    case tangibleFixedAssets
    case inventory
    case receivables
    case liquidAssets
    case unclassified

    public var label: String {
        switch self {
        case .tangibleFixedAssets:
            return "Materiële vaste activa"
        case .inventory:
            return "Voorraden"
        case .receivables:
            return "Vorderingen"
        case .liquidAssets:
            return "Liquide middelen"
        case .unclassified:
            return "Niet geclassificeerd"
        }
    }

    public var totalLabel: String {
        switch self {
        case .tangibleFixedAssets:
            return "Totaal materiële vaste activa"
        case .inventory:
            return "Totaal voorraden"
        case .receivables:
            return "Totaal vorderingen"
        case .liquidAssets:
            return "Totaal liquide middelen"
        case .unclassified:
            return "Totaal niet geclassificeerd"
        }
    }

    public var sortOrder: Int {
        switch self {
        case .tangibleFixedAssets:
            return 0
        case .inventory:
            return 1
        case .receivables:
            return 2
        case .liquidAssets:
            return 3
        case .unclassified:
            return 99
        }
    }
}
