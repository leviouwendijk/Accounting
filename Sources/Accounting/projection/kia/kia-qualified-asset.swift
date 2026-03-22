import Foundation

public struct KIAQualifiedAsset: Sendable, Hashable {
    public let entityKey: EntityKey
    public let displayName: String
    public let details: String?
    public let acquisitionDate: Date
    public let totalAmount: Decimal
    public let shares: [KIAAssetShare]

    public init(
        entityKey: EntityKey,
        displayName: String,
        details: String? = nil,
        acquisitionDate: Date,
        totalAmount: Decimal,
        shares: [KIAAssetShare]
    ) {
        self.entityKey = entityKey
        self.displayName = displayName
        self.details = details
        self.acquisitionDate = acquisitionDate
        self.totalAmount = totalAmount
        self.shares = shares
    }

    public var qualifyingAmount: Decimal {
        shares.reduce(0) { $0 + $1.amount }
    }
}
