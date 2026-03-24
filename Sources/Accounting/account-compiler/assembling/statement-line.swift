import Foundation

public struct StatementLine: Sendable {
    public let label: String
    public let rawAmount: Decimal
    public let amount: Decimal
    public let id: Int
    public let level: Int
    public let direction: Direction
    public let orientation: AccountOrientation

    public init(
        label: String,
        rawAmount: Decimal,
        amount: Decimal,
        id: Int,
        level: Int,
        direction: Direction,
        orientation: AccountOrientation
    ) {
        self.label = label
        self.rawAmount = rawAmount
        self.amount = amount
        self.id = id
        self.level = level
        self.direction = direction
        self.orientation = orientation
    }
}
