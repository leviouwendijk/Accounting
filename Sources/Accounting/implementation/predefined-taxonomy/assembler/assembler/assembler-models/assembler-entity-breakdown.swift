import Foundation

public struct EntityBreakdown: Sendable {
    /// accountId → (entityId? → amount)
    public let byAccount: [Int: [Int?: Decimal]]
}
