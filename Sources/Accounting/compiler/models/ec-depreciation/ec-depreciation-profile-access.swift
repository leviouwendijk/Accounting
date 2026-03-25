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
        entity: EntityDef,
        fallbackSchedule: DepreciationScheduleSetting?,
        fallbackAcquisition: AssetAcquisitionCost?
    ) throws -> DepreciationProfileAccess {
        if let profile = entity.profile {
            let acquisitionDate = profile.acquisition?.date ?? profile.acquisitionDate
            let commissionDate = profile.commissionDate
            let acquisition = profile.acquisition?.valuation ?? profile.acquisitionCost
            let acquisitionEntry = profile.acquisition?.entry ?? profile.acquisitionEntry
            let acquisitionAccount = profile.acquisition?.account ?? profile.acquisitionAccount

            if let commissionDate, let acquisition {
                return DepreciationProfileAccess(
                    acquisitionDate: acquisitionDate,
                    commissionDate: commissionDate,
                    acquisition: acquisition,
                    acquisitionEntry: acquisitionEntry,
                    acquisitionAccount: acquisitionAccount
                )
            }

            if commissionDate == nil, let fallbackSchedule {
                if let fallbackAcquisition {
                    return DepreciationProfileAccess(
                        acquisitionDate: acquisitionDate,
                        commissionDate: fallbackSchedule.effectiveDate,
                        acquisition: acquisition ?? fallbackAcquisition,
                        acquisitionEntry: acquisitionEntry,
                        acquisitionAccount: acquisitionAccount
                    )
                }
            }

            if acquisition == nil, let fallbackAcquisition {
                if let commissionDate {
                    return DepreciationProfileAccess(
                        acquisitionDate: acquisitionDate,
                        commissionDate: commissionDate,
                        acquisition: fallbackAcquisition,
                        acquisitionEntry: acquisitionEntry,
                        acquisitionAccount: acquisitionAccount
                    )
                }
            }

            if let fallbackSchedule, let fallbackAcquisition {
                return DepreciationProfileAccess(
                    acquisitionDate: acquisitionDate,
                    commissionDate: commissionDate ?? fallbackSchedule.effectiveDate,
                    acquisition: acquisition ?? fallbackAcquisition,
                    acquisitionEntry: acquisitionEntry,
                    acquisitionAccount: acquisitionAccount
                )
            }

            if commissionDate == nil {
                throw DepreciationProfileAccessError.missingCommissionDate(key)
            }

            throw DepreciationProfileAccessError.missingAcquisition(key)
        }

        if let fallbackSchedule, let fallbackAcquisition {
            return DepreciationProfileAccess(
                acquisitionDate: nil,
                commissionDate: fallbackSchedule.effectiveDate,
                acquisition: fallbackAcquisition,
                acquisitionEntry: nil,
                acquisitionAccount: nil
            )
        }

        throw DepreciationProfileAccessError.missingProfile(key)
    }
}

// public enum DepreciationProfileAccessError: LocalizedError, Sendable {
//     case missingProfile(EntityKey)
//     case missingCommissionDate(EntityKey)
//     case missingAcquisition(EntityKey)

//     public var errorDescription: String? {
//         switch self {
//         case .missingProfile(let key):
//             return "Missing entity profile for depreciation entity '\(key.identifier(displaying: .fullchain))'."
//         case .missingCommissionDate(let key):
//             return "Missing profile.commission_date for depreciation entity '\(key.identifier(displaying: .fullchain))'."
//         case .missingAcquisition(let key):
//             return "Missing profile.valuation.acquisition_cost for depreciation entity '\(key.identifier(displaying: .fullchain))'."
//         }
//     }
// }

// public struct DepreciationProfileAccess: Sendable {
//     public let acquisitionDate: Date?
//     public let commissionDate: Date
//     public let acquisition: AssetAcquisitionCost

//     public init(
//         acquisitionDate: Date?,
//         commissionDate: Date,
//         acquisition: AssetAcquisitionCost
//     ) {
//         self.acquisitionDate = acquisitionDate
//         self.commissionDate = commissionDate
//         self.acquisition = acquisition
//     }

//     @inlinable
//     public static func resolve(
//         for key: EntityKey,
//         entity: EntityDef,
//         fallbackSchedule: DepreciationScheduleSetting?,
//         fallbackAcquisition: AssetAcquisitionCost?
//     ) throws -> DepreciationProfileAccess {
//         if let profile = entity.profile {
//             if let commissionDate = profile.commissionDate,
//                let acquisition = profile.acquisitionCost {
//                 return DepreciationProfileAccess(
//                     acquisitionDate: profile.acquisitionDate,
//                     commissionDate: commissionDate,
//                     acquisition: acquisition
//                 )
//             }

//             if profile.commissionDate == nil, let fallbackSchedule {
//                 if let fallbackAcquisition {
//                     return DepreciationProfileAccess(
//                         acquisitionDate: profile.acquisitionDate,
//                         commissionDate: fallbackSchedule.effectiveDate,
//                         acquisition: profile.acquisitionCost ?? fallbackAcquisition
//                     )
//                 }
//             }

//             if profile.acquisitionCost == nil, let fallbackAcquisition {
//                 if let commissionDate = profile.commissionDate {
//                     return DepreciationProfileAccess(
//                         acquisitionDate: profile.acquisitionDate,
//                         commissionDate: commissionDate,
//                         acquisition: fallbackAcquisition
//                     )
//                 }
//             }

//             if let fallbackSchedule, let fallbackAcquisition {
//                 return DepreciationProfileAccess(
//                     acquisitionDate: profile.acquisitionDate,
//                     commissionDate: profile.commissionDate ?? fallbackSchedule.effectiveDate,
//                     acquisition: profile.acquisitionCost ?? fallbackAcquisition
//                 )
//             }

//             if profile.commissionDate == nil {
//                 throw DepreciationProfileAccessError.missingCommissionDate(key)
//             }

//             throw DepreciationProfileAccessError.missingAcquisition(key)
//         }

//         if let fallbackSchedule, let fallbackAcquisition {
//             return DepreciationProfileAccess(
//                 acquisitionDate: nil,
//                 commissionDate: fallbackSchedule.effectiveDate,
//                 acquisition: fallbackAcquisition
//             )
//         }

//         throw DepreciationProfileAccessError.missingProfile(key)
//     }
// }
