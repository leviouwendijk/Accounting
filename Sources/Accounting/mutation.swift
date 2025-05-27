import Foundation

public enum MovementType: String {
    case add, remove, rm, subtract
}

public struct Movement {
    public let entity: Entity
    public let account: Account
    public let amount: Double
    public let type: MovementType

    public init(
        entity: Entity, 
        account: Account,
        amount: Double,
        type: MovementType
    ) {
        self.entity = entity
        self.account = account
        self.amount = amount
        self.type = type
    }
}
