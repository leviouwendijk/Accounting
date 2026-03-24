import Foundation

public enum AssetsOverviewCategory: String, Codable, Sendable, CaseIterable {
    case other_tangible_fixed_assets
    case inventory
    case vat_receivable
    case liquid_assets
    case other_receivables
    case unclassified

    public init(metadataValue raw: String?) {
        guard let raw else {
            self = .unclassified
            return
        }

        let normalized = raw
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        switch normalized {
        case "other_tangible_fixed_assets",
             "other-tangible-fixed-assets",
             "other tangible fixed assets",
             "other_fixed_assets",
             "other-fixed-assets",
             "other fixed assets",
             "machines",
             "machine",
             "vehicles",
             "vehicle",
             "autos",
             "auto",
             "cars",
             "car",
             "equipment":
            self = .other_tangible_fixed_assets

        case "inventory",
             "voorraden",
             "voorraad":
            self = .inventory

        case "vat_receivable",
             "vat-receivable",
             "vat receivable",
             "vordering_omzetbelasting",
             "vordering-omzetbelasting",
             "vordering omzetbelasting":
            self = .vat_receivable

        case "liquid_assets",
             "liquid-assets",
             "liquid assets",
             "liquide_middelen",
             "liquide-middelen",
             "liquide middelen":
            self = .liquid_assets

        case "other_receivables",
             "other-receivables",
             "other receivables",
             "receivables",
             "vorderingen",
             "vordering":
            self = .other_receivables

        case "unclassified":
            self = .unclassified

        default:
            self = .unclassified
        }
    }

    public var lineLabel: String {
        switch self {
        case .other_tangible_fixed_assets:
            return "Overige materiële vaste activa"
        case .inventory:
            return "Voorraden"
        case .vat_receivable:
            return "Vordering omzetbelasting"
        case .liquid_assets:
            return "Liquide middelen"
        case .other_receivables:
            return "Overige vorderingen"
        case .unclassified:
            return "Niet geclassificeerd"
        }
    }

    public var section: AssetsOverviewSection {
        switch self {
        case .other_tangible_fixed_assets:
            return .tangibleFixedAssets
        case .inventory:
            return .inventory
        case .vat_receivable, .other_receivables:
            return .receivables
        case .liquid_assets:
            return .liquidAssets
        case .unclassified:
            return .unclassified
        }
    }

    public var sortOrder: Int {
        switch self {
        case .other_tangible_fixed_assets:
            return 0
        case .inventory:
            return 1
        case .vat_receivable:
            return 2
        case .other_receivables:
            return 3
        case .liquid_assets:
            return 4
        case .unclassified:
            return 99
        }
    }
}
