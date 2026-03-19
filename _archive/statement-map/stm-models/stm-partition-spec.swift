import Foundation

public struct PartitionSpec: Codable, Sendable {
    public let keys: [DimensionKey]          // e.g., [.entity] or [.entityClass]
    public let requireBalanced: Bool         // for B/S: enforce doc-splitting-like balance
    
    public init(
        keys: [DimensionKey],
        requireBalanced: Bool         // for B/S: enforce doc-splitting-like balance
    ) {
        self.keys = keys
        self.requireBalanced = requireBalanced
    }
}
