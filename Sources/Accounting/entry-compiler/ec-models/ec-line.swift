import Foundation

public struct Line: Hashable, Codable, Sendable {
    public let entity: EntityRef
    public let account: AccountPath
    public let direction: Direction
    public let amount: Decimal
    public let adjustment: InventoryAdjustment?

    public init(
        entity: EntityRef,
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
