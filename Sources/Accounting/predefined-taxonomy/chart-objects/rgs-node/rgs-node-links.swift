import Foundation

public struct RGSNodeLinks: Sendable, Codable, Hashable {
    /// Truncated sortKey at (level - 1). Nil for level == 1.
    public let parentKey: String?
    /// Truncated sortKey at level 2 (hoofdrubriek) – always present beyond L1.
    public let l2Key: String

    /// Optional resolved ids (filled at codegen for speed; otherwise set nil and use maps).
    public let parentId: Int?
    public let l2Id: Int?

    public init(parentKey: String?, l2Key: String, parentId: Int? = nil, l2Id: Int? = nil) {
        self.parentKey = parentKey
        self.l2Key = l2Key
        self.parentId = parentId
        self.l2Id = l2Id
    }
}
