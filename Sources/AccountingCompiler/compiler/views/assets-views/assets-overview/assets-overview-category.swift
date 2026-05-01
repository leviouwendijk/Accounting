import Accounting
import Foundation

// example:
    // metadata {
    //     asset_category = other_tangible_fixed_assets
    // }

// others:
//     goodwill
//     other_intangible_fixed_assets
//     buildings_and_land
//     machines_and_installations
//     other_tangible_fixed_assets
//     financial_fixed_assets
//     inventory
//     work_in_progress
//     vat_receivable
//     trade_debtors
//     other_receivables
//     securities
//     liquid_assets
//     unclassified

public enum AssetsOverviewCategory: String, Codable, Sendable, CaseIterable {
    case goodwill
    case other_intangible_fixed_assets

    case buildings_and_land
    case machines_and_installations
    case other_tangible_fixed_assets

    case financial_fixed_assets

    case inventory
    case work_in_progress

    case vat_receivable
    case trade_debtors
    case other_receivables

    case securities

    case liquid_assets

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
        case "goodwill":
            self = .goodwill

        case "other_intangible_fixed_assets",
             "other-intangible-fixed-assets",
             "other intangible fixed assets",
             "overige_immateriele_vaste_activa",
             "overige-immateriele-vaste-activa",
             "overige immateriele vaste activa",
             "overige_immateriële_vaste_activa",
             "overige-immateriële-vaste-activa",
             "overige immateriële vaste activa":
            self = .other_intangible_fixed_assets

        case "buildings_and_land",
             "buildings-and-land",
             "buildings and land",
             "gebouwen_en_terreinen",
             "gebouwen-en-terreinen",
             "gebouwen en terreinen",
             "bedrijfsgebouwen_en_terreinen",
             "bedrijfsgebouwen-en-terreinen",
             "bedrijfsgebouwen en terreinen":
            self = .buildings_and_land

        case "machines_and_installations",
             "machines-and-installations",
             "machines and installations",
             "machines_en_installaties",
             "machines-en-installaties",
             "machines en installaties",
             "machines",
             "machine":
            self = .machines_and_installations

        case "other_tangible_fixed_assets",
             "other-tangible-fixed-assets",
             "other tangible fixed assets",
             "other_fixed_assets",
             "other-fixed-assets",
             "other fixed assets",
             "overige_materiele_vaste_activa",
             "overige-materiele-vaste-activa",
             "overige materiele vaste activa",
             "overige_materiële_vaste_activa",
             "overige-materiële-vaste-activa",
             "overige materiële vaste activa",
             "vehicles",
             "vehicle",
             "autos",
             "auto",
             "cars",
             "car",
             "equipment":
            self = .other_tangible_fixed_assets

        case "financial_fixed_assets",
             "financial-fixed-assets",
             "financial fixed assets",
             "financiele_vaste_activa",
             "financiele-vaste-activa",
             "financiele vaste activa",
             "financiële_vaste_activa",
             "financiële-vaste-activa",
             "financiële vaste activa":
            self = .financial_fixed_assets

        case "inventory",
             "voorraden",
             "voorraad":
            self = .inventory

        case "work_in_progress",
             "work-in-progress",
             "work in progress",
             "onderhanden_werk",
             "onderhanden-werk",
             "onderhanden werk":
            self = .work_in_progress

        case "vat_receivable",
             "vat-receivable",
             "vat receivable",
             "vordering_omzetbelasting",
             "vordering-omzetbelasting",
             "vordering omzetbelasting":
            self = .vat_receivable

        case "trade_debtors",
             "trade-debtors",
             "trade debtors",
             "vorderingen_op_handelsdebiteuren",
             "vorderingen-op-handelsdebiteuren",
             "vorderingen op handelsdebiteuren",
             "handelsdebiteuren":
            self = .trade_debtors

        case "other_receivables",
             "other-receivables",
             "other receivables",
             "overige_vorderingen",
             "overige-vorderingen",
             "overige vorderingen",
             "receivables",
             "vorderingen",
             "vordering":
            self = .other_receivables

        case "securities",
             "effecten":
            self = .securities

        case "liquid_assets",
             "liquid-assets",
             "liquid assets",
             "liquide_middelen",
             "liquide-middelen",
             "liquide middelen":
            self = .liquid_assets

        case "unclassified":
            self = .unclassified

        default:
            self = .unclassified
        }
    }

    public var lineLabel: String {
        switch self {
        case .goodwill:
            return "Goodwill"
        case .other_intangible_fixed_assets:
            return "Overige immateriële vaste activa"

        case .buildings_and_land:
            return "(Bedrijfs)gebouwen en terreinen"
        case .machines_and_installations:
            return "Machines en installaties"
        case .other_tangible_fixed_assets:
            return "Overige materiële vaste activa"

        case .financial_fixed_assets:
            return "Financiële vaste activa"

        case .inventory:
            return "Voorraden"
        case .work_in_progress:
            return "Onderhanden werk"

        case .vat_receivable:
            return "Vordering omzetbelasting"
        case .trade_debtors:
            return "Vorderingen op handelsdebiteuren"
        case .other_receivables:
            return "Overige vorderingen"

        case .securities:
            return "Effecten"

        case .liquid_assets:
            return "Liquide middelen"

        case .unclassified:
            return "Niet geclassificeerd"
        }
    }

    public var section: AssetsOverviewSection {
        switch self {
        case .goodwill, .other_intangible_fixed_assets:
            return .intangibleFixedAssets

        case .buildings_and_land, .machines_and_installations, .other_tangible_fixed_assets:
            return .tangibleFixedAssets

        case .financial_fixed_assets:
            return .financialFixedAssets

        case .inventory, .work_in_progress:
            return .inventory

        case .vat_receivable, .trade_debtors, .other_receivables:
            return .receivables

        case .securities:
            return .securities

        case .liquid_assets:
            return .liquidAssets

        case .unclassified:
            return .unclassified
        }
    }

    public var sortOrder: Int {
        switch self {
        case .goodwill:
            return 0
        case .other_intangible_fixed_assets:
            return 1

        case .buildings_and_land:
            return 10
        case .machines_and_installations:
            return 11
        case .other_tangible_fixed_assets:
            return 12

        case .financial_fixed_assets:
            return 20

        case .inventory:
            return 30
        case .work_in_progress:
            return 31

        case .vat_receivable:
            return 40
        case .trade_debtors:
            return 41
        case .other_receivables:
            return 42

        case .securities:
            return 50

        case .liquid_assets:
            return 60

        case .unclassified:
            return 99
        }
    }
}
