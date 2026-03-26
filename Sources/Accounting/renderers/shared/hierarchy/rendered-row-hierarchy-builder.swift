import Foundation

enum RenderedRowHierarchyBuilder {
    static func makeMap(
        idsInOrder: [Int],
        parentById: [Int: Int],
        sectionRootId: Int? = nil
    ) -> [Int: RenderedRowHierarchy] {
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

        var out: [Int: RenderedRowHierarchy] = [:]

        func walk(
            parentId: Int?,
            depth: Int,
            ancestorHasNextSiblings: [Bool]
        ) {
            let children = childrenByParent[parentId] ?? []

            for (index, id) in children.enumerated() {
                let hasNextSibling = index < (children.count - 1)

                out[id] = RenderedRowHierarchy(
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
