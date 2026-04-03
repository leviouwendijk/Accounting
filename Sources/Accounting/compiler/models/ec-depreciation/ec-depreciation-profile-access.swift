import Foundation

public enum DepreciationProfileAccessError: LocalizedError, Sendable {
    case missingProfile(EntityKey)
    case missingCommissionDate(EntityKey)
    case missingAcquisition(EntityKey)

    public var errorDescription: String? {
        switch self {
        case .missingProfile(let key):
            return "Missing entity profile for depreciation entity '\(key.identifier(displaying: .fullchain))'."
        case .missingCommissionDate(let key):
            return "Missing profile.commission_date for depreciation entity '\(key.identifier(displaying: .fullchain))'."
        case .missingAcquisition(let key):
            return "Missing profile.acquisition.valuation.acquisition_cost for depreciation entity '\(key.identifier(displaying: .fullchain))'."
        }
    }
}

public struct DepreciationProfileAccess: Sendable {
    public let acquisitionDate: Date?
    public let commissionDate: Date
    public let acquisition: AssetAcquisitionCost

    public let acquisitionEntry: Int?
    public let acquisitionAccount: AccountRef?

    public init(
        acquisitionDate: Date?,
        commissionDate: Date,
        acquisition: AssetAcquisitionCost,
        acquisitionEntry: Int? = nil,
        acquisitionAccount: AccountRef? = nil
    ) {
        self.acquisitionDate = acquisitionDate
        self.commissionDate = commissionDate
        self.acquisition = acquisition
        self.acquisitionEntry = acquisitionEntry
        self.acquisitionAccount = acquisitionAccount
    }

    @inlinable
    public static func resolve(
        for key: EntityKey,
        entity: EntityDef
    ) throws -> DepreciationProfileAccess {
        guard let profile = entity.profile else {
            throw DepreciationProfileAccessError.missingProfile(key)
        }

        let acquisitionDate = profile.acquisition?.date ?? profile.acquisitionDate
        let acquisitionEntry = profile.acquisition?.entry ?? profile.acquisitionEntry
        let acquisitionAccount = profile.acquisition?.account ?? profile.acquisitionAccount

        guard let commissionDate = profile.commissionDate else {
            throw DepreciationProfileAccessError.missingCommissionDate(key)
        }

        guard let acquisition = profile.acquisition?.valuation ?? profile.acquisitionCost else {
            throw DepreciationProfileAccessError.missingAcquisition(key)
        }

        return DepreciationProfileAccess(
            acquisitionDate: acquisitionDate,
            commissionDate: commissionDate,
            acquisition: acquisition,
            acquisitionEntry: acquisitionEntry,
            acquisitionAccount: acquisitionAccount
        )
    }
}
