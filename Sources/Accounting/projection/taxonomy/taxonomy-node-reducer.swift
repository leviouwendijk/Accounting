import Foundation

public enum TaxonomyNodeReducer {
    public static func reduceToTopLevelUniqueNodes(
        _ nodeIds: some Sequence<Int>,
        parentById: [Int: Int]
    ) -> [Int] {
        let selected = Set(nodeIds)
        guard !selected.isEmpty else {
            return []
        }

        var kept: [Int] = []

        for nodeId in selected.sorted() {
            if hasSelectedAncestor(
                nodeId,
                selected: selected,
                parentById: parentById
            ) {
                continue
            }

            kept.append(nodeId)
        }

        return kept
    }

    @inline(__always)
    private static func hasSelectedAncestor(
        _ nodeId: Int,
        selected: Set<Int>,
        parentById: [Int: Int]
    ) -> Bool {
        var current = parentById[nodeId]

        while let ancestor = current {
            if selected.contains(ancestor) {
                return true
            }

            current = parentById[ancestor]
        }

        return false
    }
}
