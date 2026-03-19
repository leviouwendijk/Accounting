import Foundation
import plate
import Extensions

public typealias LegacyAssetItemsPage = ExportPage<LegacyAssetItem>

/// Legacy export write-off method, as emitted by the old system.
public enum LegacyWriteOffMethod: String, Sendable, Codable, StringParsableEnum {
    case straightLine            = "Straight Line"
    case doubleDecliningBalance  = "Double-Declining Balance"
    case sumOfTheYearsDigits     = "Sum of the Year's Digits"
    case unitsOfProduction       = "Units of Production"

    /// Map to `.ec` DSL tokens (see depreciation DSL examples).
    @inlinable
    public func convertForEC() -> String {
        switch self {
        case .straightLine:           return "straight_line"
        case .doubleDecliningBalance: return "double_declining_balance"
        case .sumOfTheYearsDigits:    return "sum_of_year_digits"
        case .unitsOfProduction:      return "units_of_production"
        }
    }
}

/// Legacy tangibility flag (kept separate from account tangibility to avoid coupling).
public enum LegacyTangibility: String, Sendable, Codable {
    case tangible   = "Tangible"
    case intangible = "Intangible"
}

/// Legacy Asset Item (depreciation source data).
/// NOTE: numeric fields are strings in the export; we keep them as `String?`
/// to preserve exact payload + defer Decimal parsing to callers, same as journal entries.
public struct LegacyAssetItem: Codable, Sendable, JSONReadable, JSONWritable, Identifiable {
    public let id: Int

    public let journalEntryId: Int?
    public let assetPrimaryAccountId: Int?

    public let description: String?

    // Monetary and numeric inputs (stringly-typed per export)
    public let assetCost: String?
    public let usefulLife: String?
    public let residualValue: String?
    public let residualValuePercentage: String?

    /// Commission (in-service) date as YYYY-MM-DD from export.
    public let commissionDate: String?

    public let tangibility: LegacyTangibility?
    public let writeOffMethod: LegacyWriteOffMethod?

    public init(
        id: Int,
        journalEntryId: Int?,
        assetPrimaryAccountId: Int?,
        description: String?,
        assetCost: String?,
        usefulLife: String?,
        residualValue: String?,
        residualValuePercentage: String?,
        commissionDate: String?,
        tangibility: LegacyTangibility?,
        writeOffMethod: LegacyWriteOffMethod?
    ) {
        self.id = id
        self.journalEntryId = journalEntryId
        self.assetPrimaryAccountId = assetPrimaryAccountId
        self.description = description
        self.assetCost = assetCost
        self.usefulLife = usefulLife
        self.residualValue = residualValue
        self.residualValuePercentage = residualValuePercentage
        self.commissionDate = commissionDate
        self.tangibility = tangibility
        self.writeOffMethod = writeOffMethod
    }

    enum CodingKeys: String, CodingKey {
        case id
        case journalEntryId          = "journal_entry_id"
        case assetPrimaryAccountId   = "asset_primary_account_id"
        case description

        case assetCost               = "asset_cost"
        case usefulLife              = "useful_life"
        case residualValue           = "residual_value"
        case residualValuePercentage = "residual_value_percentage"

        case commissionDate          = "commission_date"
        case tangibility
        case writeOffMethod          = "write_off_method"
    }
}
