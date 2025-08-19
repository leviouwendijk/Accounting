import Foundation

public struct Line: Hashable, Codable, Sendable {
    public let entity: EntityPath
    public let account: AccountPath
    public let direction: Direction
    public let amount: Decimal
    public let adjustment: InventoryAdjustment?

    public init(
        entity: EntityPath,
        account: AccountPath,
        direction: Direction,
        amount: Decimal,
        adjustment: InventoryAdjustment? = nil
    ) {
        self.entity = entity
        self.account = account
        self.direction = direction
        self.amount = amount
        self.adjustment = adjustment
    }
}
