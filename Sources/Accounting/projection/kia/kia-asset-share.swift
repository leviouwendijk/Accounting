import Foundation

public struct KIAAssetShare: Sendable, Hashable {
    public let owner: EntityRef?
    public let ownerLabel: String
    public let percentage: Decimal
    public let amount: Decimal

    public init(
        owner: EntityRef?,
        ownerLabel: String,
        percentage: Decimal,
        amount: Decimal
    ) {
        self.owner = owner
        self.ownerLabel = ownerLabel
        self.percentage = percentage
        self.amount = amount
    }
}
