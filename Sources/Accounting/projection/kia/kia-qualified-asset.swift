import Foundation

public struct KIAQualifiedAsset: Sendable, Hashable {
    public let entityKey: EntityKey
    public let displayName: String
    public let acquisitionDate: Date
    public let totalAmount: Decimal
    public let shares: [KIAAssetShare]

    public init(
        entityKey: EntityKey,
        displayName: String,
        acquisitionDate: Date,
        totalAmount: Decimal,
        shares: [KIAAssetShare]
    ) {
        self.entityKey = entityKey
        self.displayName = displayName
        self.acquisitionDate = acquisitionDate
        self.totalAmount = totalAmount
        self.shares = shares
    }

    public var qualifyingAmount: Decimal {
        shares.reduce(0) { $0 + $1.amount }
    }
}
