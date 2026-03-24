import Foundation

extension StatementHTMLRenderer {
    struct RowHierarchy: Sendable {
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

    static func makeRowHierarchyMap(
        idsInOrder: [Int],
        parentById: [Int: Int],
        sectionRootId: Int? = nil
    ) -> [Int: RowHierarchy] {
        let visible = Set(idsInOrder)

        var normalizedParentById: [Int: Int?] = [:]
        for id in idsInOrder {
            let rawParent = parentById[id]

            if let root = sectionRootId, id == root {
                normalizedParentById[id] = nil
            } else if let p = rawParent, visible.contains(p) {
                normalizedParentById[id] = p
            } else {
                normalizedParentById[id] = nil
            }
        }

        var childrenByParent: [Int?: [Int]] = [:]
        for id in idsInOrder {
            let parent = normalizedParentById[id] ?? nil
            childrenByParent[parent, default: []].append(id)
        }

        var out: [Int: RowHierarchy] = [:]

        func walk(
            parentId: Int?,
            depth: Int,
            ancestorHasNextSiblings: [Bool]
        ) {
            let children = childrenByParent[parentId] ?? []

            for (index, id) in children.enumerated() {
                let hasNextSibling = index < (children.count - 1)

                out[id] = RowHierarchy(
                    id: id,
                    parentId: parentId,
                    depth: depth,
                    hasNextSibling: hasNextSibling,
                    ancestorHasNextSiblings: ancestorHasNextSiblings
                )

                walk(
                    parentId: id,
                    depth: depth + 1,
                    ancestorHasNextSiblings: ancestorHasNextSiblings + [hasNextSibling]
                )
            }
        }

        walk(
            parentId: nil,
            depth: 0,
            ancestorHasNextSiblings: []
        )

        return out
    }
}
