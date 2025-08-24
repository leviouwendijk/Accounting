import Foundation

public enum InventoryAdjustmentDirection: String, Codable, Sendable, Equatable, Hashable {
    case addition, add
    case reduction, remove
    // case none
}

public struct InventoryAdjustment: Codable, Sendable, Equatable, Hashable {
    public let mutation: InventoryAdjustmentDirection
    public let count: Double

    // if making default init, with .none case:
    
    // public init(
    //     mutation: InventoryAdjustmentDirection = .none,
    //     count: Double = 0.0
    // ) {
    //     self.mutation = mutation
    //     self.count = count
    // }

    // if nillable in J/E:

    public init(
        mutation: InventoryAdjustmentDirection,
        count: Double
    ) {
        self.mutation = mutation
        self.count = count
    }
}
