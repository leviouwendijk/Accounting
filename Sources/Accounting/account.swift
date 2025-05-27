import Foundation

public struct Account {
    public let id: String
    public let name: String
    public let accountClass: AccountClass
    public let direction: Direction
    public var balance: Double

    public init(
        id: String, 
        name: String, 
        type: AccountClass, 
        direction: Direction, 
        balance: Double = 0.0
    ) {
        self.id = id
        self.name = name
        self.accountClass = type
        self.direction = direction
        self.balance = balance
    }
}

public enum AccountClass: String {
    case dividend, expense, asset, liability, equity, revenue
}


