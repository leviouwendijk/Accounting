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

extension StatementHTMLRenderer {
    struct PresentationHierarchy: Sendable {
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

    static func makePresentationHierarchyMap(
        idsInOrder: [Int],
        canonicalParentById: [Int: Int],
        presentationDepthById: [Int: Int]
    ) -> [Int: PresentationHierarchy] {
        let visible = Set(idsInOrder)

        @inline(__always)
        func visibleAncestors(of id: Int) -> [Int] {
            var out: [Int] = []
            var cur = canonicalParentById[id]

            while let c = cur {
                if visible.contains(c) {
                    out.append(c)
                }
                cur = canonicalParentById[c]
            }

            return out
        }

        var presentationParentById: [Int: Int?] = [:]

        for id in idsInOrder {
            let depth = presentationDepthById[id] ?? 0

            if depth == 0 {
                presentationParentById[id] = nil
                continue
            }

            let targetParentDepth = depth - 1

            let parent = visibleAncestors(of: id).first(where: { ancestor in
                (presentationDepthById[ancestor] ?? 0) == targetParentDepth
            })

            presentationParentById[id] = parent
        }

        var childrenByParent: [Int?: [Int]] = [:]
        for id in idsInOrder {
            let parent = presentationParentById[id] ?? nil
            childrenByParent[parent, default: []].append(id)
        }

        var out: [Int: PresentationHierarchy] = [:]

        func walk(
            parentId: Int?,
            ancestorHasNextSiblings: [Bool]
        ) {
            let children = childrenByParent[parentId] ?? []

            for (index, id) in children.enumerated() {
                let hasNextSibling = index < (children.count - 1)
                let depth = presentationDepthById[id] ?? 0

                out[id] = PresentationHierarchy(
                    id: id,
                    parentId: parentId,
                    depth: depth,
                    hasNextSibling: hasNextSibling,
                    ancestorHasNextSiblings: ancestorHasNextSiblings
                )

                walk(
                    parentId: id,
                    ancestorHasNextSiblings: ancestorHasNextSiblings + [hasNextSibling]
                )
            }
        }

        walk(
            parentId: nil,
            ancestorHasNextSiblings: []
        )

        return out
    }
}
