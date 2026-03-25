import Foundation

public struct EntityUnitProfile: Sendable, Codable {
    public var acquisitionDate: Date?
    public var commissionDate: Date?
    public var acquisitionCost: AssetAcquisitionCost?

    public init(
        acquisitionDate: Date? = nil,
        commissionDate: Date? = nil,
        acquisitionCost: AssetAcquisitionCost? = nil
    ) {
        self.acquisitionDate = acquisitionDate
        self.commissionDate = commissionDate
        self.acquisitionCost = acquisitionCost
    }
}
