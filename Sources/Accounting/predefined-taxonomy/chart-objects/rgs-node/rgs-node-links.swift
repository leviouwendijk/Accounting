import Foundation

public struct RGSNodeLinksXLSXSortingKey: Sendable, Codable, Hashable {
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

public struct RGSNodeLinksPresentationBase: Sendable, Codable, Hashable {
    public let parentId: Int
    public let presentationRole: String
    public let order: Decimal
    public let preferredLabel: String?
    
    public init(
        parentId: Int,
        presentationRole: String,
        order: Decimal,
        preferredLabel: String?
    ) {
        self.parentId = parentId
        self.presentationRole = presentationRole
        self.order = order
        self.preferredLabel = preferredLabel
    }
}
