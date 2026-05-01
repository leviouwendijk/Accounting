import Accounting
import Foundation

enum RenderedRowHierarchyBuilder {
    struct Diagnostic: Sendable {
        enum Kind: Sendable {
            case promotedToVisibleAncestor(
                rawParentId: Int,
                promotedParentId: Int
            )
            case promotedToRoot(
                rawParentId: Int
            )
            case missingFromOutput
        }

        let id: Int
        let kind: Kind
    }

    struct Output: Sendable {
        let map: [Int: RenderedRowHierarchy]
        let diagnostics: [Diagnostic]
    }

    static func makeMap(
        idsInOrder: [Int],
        parentById: [Int: Int],
        sectionRootId: Int? = nil,
        promoteToNearestVisibleAncestor: Bool = true
    ) -> [Int: RenderedRowHierarchy] {
        makeOutput(
            idsInOrder: idsInOrder,
            parentById: parentById,
            sectionRootId: sectionRootId,
            promoteToNearestVisibleAncestor: promoteToNearestVisibleAncestor
        ).map
    }

    static func makeOutput(
        idsInOrder: [Int],
        parentById: [Int: Int],
        sectionRootId: Int? = nil,
        promoteToNearestVisibleAncestor: Bool = true
    ) -> Output {
        let visible = Set(idsInOrder)

        var normalizedParentById: [Int: Int?] = [:]
        var diagnostics: [Diagnostic] = []

        func nearestVisibleAncestor(
            startingAt rawParentId: Int?
        ) -> Int? {
            var cursor = rawParentId
            var seen = Set<Int>()

            while let candidate = cursor {
                if !seen.insert(candidate).inserted {
                    return nil
                }

                if visible.contains(candidate) {
                    return candidate
                }

                cursor = parentById[candidate]
            }

            return nil
        }

        for id in idsInOrder {
            let rawParent = parentById[id]

            if let root = sectionRootId, id == root {
                normalizedParentById[id] = nil
                continue
            }

            if let p = rawParent, visible.contains(p) {
                normalizedParentById[id] = p
                continue
            }

            if promoteToNearestVisibleAncestor,
               let rawParent,
               let promoted = nearestVisibleAncestor(startingAt: rawParent) {
                normalizedParentById[id] = promoted

                if promoted != rawParent {
                    diagnostics.append(
                        Diagnostic(
                            id: id,
                            kind: .promotedToVisibleAncestor(
                                rawParentId: rawParent,
                                promotedParentId: promoted
                            )
                        )
                    )
                }

                continue
            }

            normalizedParentById[id] = nil

            if let rawParent {
                diagnostics.append(
                    Diagnostic(
                        id: id,
                        kind: .promotedToRoot(
                            rawParentId: rawParent
                        )
                    )
                )
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

        for id in idsInOrder where out[id] == nil {
            diagnostics.append(
                Diagnostic(
                    id: id,
                    kind: .missingFromOutput
                )
            )
        }

        return Output(
            map: out,
            diagnostics: diagnostics
        )
    }

    static func printDiagnostics(
        _ output: Output,
        idsInOrder: [Int],
        nameById: [Int: String] = [:],
        sortKeyById: [Int: String] = [:],
        title: String = "Rendered row hierarchy diagnostics"
    ) {
        Swift.print(title)
        Swift.print(String(repeating: "─", count: title.count))

        guard !output.diagnostics.isEmpty else {
            Swift.print("(no issues)")
            return
        }

        let diagnosticsById = Dictionary(
            grouping: output.diagnostics,
            by: \.id
        )

        for id in idsInOrder {
            guard let diagnostics = diagnosticsById[id], !diagnostics.isEmpty else {
                continue
            }

            let name = nameById[id] ?? "—"
            let key = sortKeyById[id] ?? "—"

            Swift.print("")
            Swift.print("id=\(id) key=\(key) label=\(name)")

            for diagnostic in diagnostics {
                switch diagnostic.kind {
                case .promotedToVisibleAncestor(
                    let rawParentId,
                    let promotedParentId
                ):
                    Swift.print(
                        "  - promoted to visible ancestor: rawParent=\(rawParentId), promotedParent=\(promotedParentId)"
                    )

                case .promotedToRoot(let rawParentId):
                    Swift.print(
                        "  - promoted to root: rawParent=\(rawParentId)"
                    )

                case .missingFromOutput:
                    Swift.print(
                        "  - missing from rendered hierarchy output"
                    )
                }
            }
        }
    }
}

// enum RenderedRowHierarchyBuilder {
//     static func makeMap(
//         idsInOrder: [Int],
//         parentById: [Int: Int],
//         sectionRootId: Int? = nil
//     ) -> [Int: RenderedRowHierarchy] {
//         let visible = Set(idsInOrder)

//         var normalizedParentById: [Int: Int?] = [:]

//         for id in idsInOrder {
//             let rawParent = parentById[id]

//             if let root = sectionRootId, id == root {
//                 normalizedParentById[id] = nil
//             } else if let p = rawParent, visible.contains(p) {
//                 normalizedParentById[id] = p
//             } else {
//                 normalizedParentById[id] = nil
//             }
//         }

//         var childrenByParent: [Int?: [Int]] = [:]

//         for id in idsInOrder {
//             let parent = normalizedParentById[id] ?? nil
//             childrenByParent[parent, default: []].append(id)
//         }

//         var out: [Int: RenderedRowHierarchy] = [:]

//         func walk(
//             parentId: Int?,
//             depth: Int,
//             ancestorHasNextSiblings: [Bool]
//         ) {
//             let children = childrenByParent[parentId] ?? []

//             for (index, id) in children.enumerated() {
//                 let hasNextSibling = index < (children.count - 1)

//                 out[id] = RenderedRowHierarchy(
//                     id: id,
//                     parentId: parentId,
//                     depth: depth,
//                     hasNextSibling: hasNextSibling,
//                     ancestorHasNextSiblings: ancestorHasNextSiblings
//                 )

//                 walk(
//                     parentId: id,
//                     depth: depth + 1,
//                     ancestorHasNextSiblings: ancestorHasNextSiblings + [hasNextSibling]
//                 )
//             }
//         }

//         walk(
//             parentId: nil,
//             depth: 0,
//             ancestorHasNextSiblings: []
//         )

//         return out
//     }
// }
