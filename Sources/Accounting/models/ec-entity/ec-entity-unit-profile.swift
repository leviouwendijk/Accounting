import Foundation

public struct EntityUnitProfile: Sendable, Codable {
    public var acquisition: AssetAcquisitionProfile?
    public var commissionDate: Date?

    public init(
        acquisition: AssetAcquisitionProfile? = nil,
        commissionDate: Date? = nil
    ) {
        self.acquisition = acquisition
        self.commissionDate = commissionDate
    }

    public init(
        acquisitionDate: Date? = nil,
        commissionDate: Date? = nil,
        acquisitionCost: AssetAcquisitionCost? = nil
    ) {
        self.acquisition = AssetAcquisitionProfile(
            date: acquisitionDate,
            valuation: acquisitionCost
        )
        self.commissionDate = commissionDate
    }

    public var acquisitionDate: Date? {
        get {
            acquisition?.date
        }
        set {
            if acquisition == nil {
                acquisition = .init()
            }
            acquisition?.date = newValue
        }
    }

    public var acquisitionCost: AssetAcquisitionCost? {
        get {
            acquisition?.valuation
        }
        set {
            if acquisition == nil {
                acquisition = .init()
            }
            acquisition?.valuation = newValue
        }
    }

    public var acquisitionEntry: Int? {
        get {
            acquisition?.entry
        }
        set {
            if acquisition == nil {
                acquisition = .init()
            }
            acquisition?.entry = newValue
        }
    }

    public var acquisitionAccount: AccountRef? {
        get {
            acquisition?.account
        }
        set {
            if acquisition == nil {
                acquisition = .init()
            }
            acquisition?.account = newValue
        }
    }
}

// public struct EntityUnitProfile: Sendable, Codable {
//     public var acquisitionDate: Date?
//     public var commissionDate: Date?
//     public var acquisitionCost: AssetAcquisitionCost?

//     public init(
//         acquisitionDate: Date? = nil,
//         commissionDate: Date? = nil,
//         acquisitionCost: AssetAcquisitionCost? = nil
//     ) {
//         self.acquisitionDate = acquisitionDate
//         self.commissionDate = commissionDate
//         self.acquisitionCost = acquisitionCost
//     }
// }
