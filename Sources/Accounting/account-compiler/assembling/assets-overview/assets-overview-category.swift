import Foundation

public enum AssetsOverviewCategory: String, Codable, Sendable, CaseIterable {
    case machines
    case vehicles
    case equipment
    case inventory
    case other_fixed_assets
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
        case "machines", "machine":
            self = .machines

        case "vehicles", "vehicle", "autos", "auto", "cars", "car":
            self = .vehicles

        case "equipment":
            self = .equipment

        case "inventory":
            self = .inventory

        case "other_fixed_assets", "other-fixed-assets", "other fixed assets":
            self = .other_fixed_assets

        case "unclassified":
            self = .unclassified

        default:
            self = .unclassified
        }
    }

    public var label: String {
        switch self {
        case .machines:
            return "Machines"
        case .vehicles:
            return "Vehicles"
        case .equipment:
            return "Equipment"
        case .inventory:
            return "Inventory"
        case .other_fixed_assets:
            return "Other fixed assets"
        case .unclassified:
            return "Unclassified"
        }
    }
}
