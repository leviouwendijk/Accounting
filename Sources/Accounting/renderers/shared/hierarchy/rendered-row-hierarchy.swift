import Foundation

struct RenderedRowHierarchy: Sendable {
    let id: Int
    let parentId: Int?
    let depth: Int
    let hasNextSibling: Bool
    let ancestorHasNextSiblings: [Bool]

    init(
        id: Int,
        parentId: Int?,
        depth: Int,
        hasNextSibling: Bool,
        ancestorHasNextSiblings: [Bool]
    ) {
        self.id = id
        self.parentId = parentId
        self.depth = depth
        self.hasNextSibling = hasNextSibling
        self.ancestorHasNextSiblings = ancestorHasNextSiblings
    }
}
