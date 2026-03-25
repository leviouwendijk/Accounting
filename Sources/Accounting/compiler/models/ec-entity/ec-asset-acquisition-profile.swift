import Foundation

public struct AssetAcquisitionProfile: Sendable, Codable {
    public var date: Date?
    public var entry: Int?
    public var account: AccountRef?
    public var valuation: AssetAcquisitionCost?

    public init(
        date: Date? = nil,
        entry: Int? = nil,
        account: AccountRef? = nil,
        valuation: AssetAcquisitionCost? = nil
    ) {
        self.date = date
        self.entry = entry
        self.account = account
        self.valuation = valuation
    }
}
