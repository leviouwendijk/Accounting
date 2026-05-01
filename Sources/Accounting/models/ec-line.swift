import Foundation
import Position

public struct Line: Hashable, Codable, Sendable {
    public let entity: EntityRef
    public let account: AccountRef
    public let direction: Direction
    public let amount: Decimal
    public let adjustment: InventoryAdjustment?
    public let location: Position?

    public init(
        entity: EntityRef,
        account: AccountRef,
        direction: Direction,
        amount: Decimal,
        adjustment: InventoryAdjustment? = nil,
        location: Position? = nil
    ) {
        self.entity = entity
        self.account = account
        self.direction = direction
        self.amount = amount
        self.adjustment = adjustment
        self.location = location
    }
}
