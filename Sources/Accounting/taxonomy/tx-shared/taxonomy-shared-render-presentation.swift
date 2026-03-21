import Foundation

extension TaxonomyShared {
    public static func renderPresentationLink(
        _ link: TaxonomyPresentationLink,
        labelsByConcept: [String: String],
        factsByConcept: [String: TaxonomyComputedFact],
        pruneEmpty: Bool = false
    ) {
        let orderedChildrenByParent = orderedChildrenByParent(link)
        let childConcepts = Set(link.arcs.map(\.child))
        let rootConcepts = link.locators.keys.filter { !childConcepts.contains($0) }.sorted()

        print("presentation:")

        if rootConcepts.isEmpty {
            print("  no roots")
            return
        }

        for root in rootConcepts {
            if pruneEmpty,
               !shouldRenderPresentationNode(
                    locatorLabel: root,
                    link: link,
                    orderedChildrenByParent: orderedChildrenByParent,
                    flattenedFactsByConcept: factsByConcept
               ) {
                continue
            }

            var visited = Set<String>()

            renderPresentationNode(
                locatorLabel: root,
                link: link,
                labelsByConcept: labelsByConcept,
                factsByConcept: factsByConcept,
                orderedChildrenByParent: orderedChildrenByParent,
                pruneEmpty: pruneEmpty,
                indent: 0,
                visited: &visited
            )
        }
    }

    public static func renderPresentationLink(
        _ link: TaxonomyPresentationLink,
        labelsByConcept: [String: String],
        factsByConcept: [String: [TaxonomyComputedMappedFact]],
        source: TaxonomySourceData,
        pruneEmpty: Bool = false
    ) {
        let orderedChildrenByParent = orderedChildrenByParent(link)
        let childConcepts = Set(link.arcs.map(\.child))
        let rootConcepts = link.locators.keys.filter { !childConcepts.contains($0) }.sorted()

        print("presentation:")

        if rootConcepts.isEmpty {
            print("  no roots")
            return
        }

        for root in rootConcepts {
            if pruneEmpty,
               !shouldRenderPresentationNode(
                    locatorLabel: root,
                    link: link,
                    orderedChildrenByParent: orderedChildrenByParent,
                    dimensionalFactsByConcept: factsByConcept
               ) {
                continue
            }

            var visited = Set<String>()

            renderPresentationNode(
                locatorLabel: root,
                link: link,
                labelsByConcept: labelsByConcept,
                factsByConcept: factsByConcept,
                orderedChildrenByParent: orderedChildrenByParent,
                source: source,
                pruneEmpty: pruneEmpty,
                indent: 0,
                visited: &visited
            )
        }
    }
}

private extension TaxonomyShared {
    static func orderedChildrenByParent(
        _ link: TaxonomyPresentationLink
    ) -> [String: [TaxonomyPresentationArc]] {
        let grouped = Dictionary(grouping: link.arcs, by: \.parent)

        var out: [String: [TaxonomyPresentationArc]] = [:]
        for (parent, arcs) in grouped {
            out[parent] = arcs.sorted { lhs, rhs in
                switch (lhs.order, rhs.order) {
                case let (l?, r?):
                    if l == r {
                        return lhs.child < rhs.child
                    }

                    return l < r

                case (.some, .none):
                    return true

                case (.none, .some):
                    return false

                case (.none, .none):
                    return lhs.child < rhs.child
                }
            }
        }

        return out
    }

    static func shouldRenderPresentationNode(
        locatorLabel: String,
        link: TaxonomyPresentationLink,
        orderedChildrenByParent: [String: [TaxonomyPresentationArc]],
        flattenedFactsByConcept: [String: TaxonomyComputedFact]
    ) -> Bool {
        guard let href = link.locators[locatorLabel] else {
            return false
        }

        let concept = conceptName(from: href)

        if flattenedFactsByConcept[concept] != nil {
            return true
        }

        for arc in orderedChildrenByParent[locatorLabel] ?? [] {
            if shouldRenderPresentationNode(
                locatorLabel: arc.child,
                link: link,
                orderedChildrenByParent: orderedChildrenByParent,
                flattenedFactsByConcept: flattenedFactsByConcept
            ) {
                return true
            }
        }

        return false
    }

    static func shouldRenderPresentationNode(
        locatorLabel: String,
        link: TaxonomyPresentationLink,
        orderedChildrenByParent: [String: [TaxonomyPresentationArc]],
        dimensionalFactsByConcept: [String: [TaxonomyComputedMappedFact]]
    ) -> Bool {
        guard let href = link.locators[locatorLabel] else {
            return false
        }

        let concept = conceptName(from: href)

        if let facts = dimensionalFactsByConcept[concept], !facts.isEmpty {
            return true
        }

        for arc in orderedChildrenByParent[locatorLabel] ?? [] {
            if shouldRenderPresentationNode(
                locatorLabel: arc.child,
                link: link,
                orderedChildrenByParent: orderedChildrenByParent,
                dimensionalFactsByConcept: dimensionalFactsByConcept
            ) {
                return true
            }
        }

        return false
    }

    static func renderPresentationNode(
        locatorLabel: String,
        link: TaxonomyPresentationLink,
        labelsByConcept: [String: String],
        factsByConcept: [String: TaxonomyComputedFact],
        orderedChildrenByParent: [String: [TaxonomyPresentationArc]],
        pruneEmpty: Bool,
        indent: Int,
        visited: inout Set<String>
    ) {
        guard !visited.contains(locatorLabel) else {
            return
        }

        if pruneEmpty,
           !shouldRenderPresentationNode(
                locatorLabel: locatorLabel,
                link: link,
                orderedChildrenByParent: orderedChildrenByParent,
                flattenedFactsByConcept: factsByConcept
           ) {
            return
        }

        visited.insert(locatorLabel)

        guard let href = link.locators[locatorLabel] else {
            return
        }

        let concept = conceptName(from: href)
        let label = labelsByConcept[concept] ?? concept
        let prefix = String(repeating: "    ", count: indent)

        if let fact = factsByConcept[concept] {
            print("\(prefix)\(label) = \(decimalString(fact.amount))")
        } else {
            print("\(prefix)\(label)")
        }

        for arc in orderedChildrenByParent[locatorLabel] ?? [] {
            renderPresentationNode(
                locatorLabel: arc.child,
                link: link,
                labelsByConcept: labelsByConcept,
                factsByConcept: factsByConcept,
                orderedChildrenByParent: orderedChildrenByParent,
                pruneEmpty: pruneEmpty,
                indent: indent + 1,
                visited: &visited
            )
        }
    }

    static func renderPresentationNode(
        locatorLabel: String,
        link: TaxonomyPresentationLink,
        labelsByConcept: [String: String],
        factsByConcept: [String: [TaxonomyComputedMappedFact]],
        orderedChildrenByParent: [String: [TaxonomyPresentationArc]],
        source: TaxonomySourceData,
        pruneEmpty: Bool,
        indent: Int,
        visited: inout Set<String>
    ) {
        guard !visited.contains(locatorLabel) else {
            return
        }

        if pruneEmpty,
           !shouldRenderPresentationNode(
                locatorLabel: locatorLabel,
                link: link,
                orderedChildrenByParent: orderedChildrenByParent,
                dimensionalFactsByConcept: factsByConcept
           ) {
            return
        }

        visited.insert(locatorLabel)

        guard let href = link.locators[locatorLabel] else {
            return
        }

        let concept = conceptName(from: href)
        let label = labelsByConcept[concept] ?? concept
        let prefix = String(repeating: "    ", count: indent)

        if let facts = factsByConcept[concept], !facts.isEmpty {
            let total = facts.reduce(Decimal.zero) { partial, fact in
                partial + fact.amount
            }

            if let summary = summarizedPresentationDimensions(facts, source: source) {
                print("\(prefix)\(label) = \(decimalString(total)) :: \(summary)")
            } else {
                print("\(prefix)\(label) = \(decimalString(total))")
            }
        } else {
            print("\(prefix)\(label)")
        }

        for arc in orderedChildrenByParent[locatorLabel] ?? [] {
            renderPresentationNode(
                locatorLabel: arc.child,
                link: link,
                labelsByConcept: labelsByConcept,
                factsByConcept: factsByConcept,
                orderedChildrenByParent: orderedChildrenByParent,
                source: source,
                pruneEmpty: pruneEmpty,
                indent: indent + 1,
                visited: &visited
            )
        }
    }
}

// import Foundation

// extension TaxonomyShared {
//     public static func renderPresentationLink(
//         _ link: TaxonomyPresentationLink,
//         labelsByConcept: [String: String],
//         factsByConcept: [String: TaxonomyComputedFact]
//     ) {
//         let orderedChildrenByParent = orderedChildrenByParent(link)
//         let childConcepts = Set(link.arcs.map(\.child))
//         let rootConcepts = link.locators.keys.filter { !childConcepts.contains($0) }.sorted()

//         print("presentation:")

//         if rootConcepts.isEmpty {
//             print("  no roots")
//             return
//         }

//         for root in rootConcepts {
//             var visited = Set<String>()

//             renderPresentationNode(
//                 locatorLabel: root,
//                 link: link,
//                 labelsByConcept: labelsByConcept,
//                 factsByConcept: factsByConcept,
//                 orderedChildrenByParent: orderedChildrenByParent,
//                 indent: 0,
//                 visited: &visited
//             )
//         }
//     }

//     public static func renderPresentationLink(
//         _ link: TaxonomyPresentationLink,
//         labelsByConcept: [String: String],
//         factsByConcept: [String: [TaxonomyComputedMappedFact]],
//         source: TaxonomySourceData
//     ) {
//         let orderedChildrenByParent = orderedChildrenByParent(link)
//         let childConcepts = Set(link.arcs.map(\.child))
//         let rootConcepts = link.locators.keys.filter { !childConcepts.contains($0) }.sorted()

//         print("presentation:")

//         if rootConcepts.isEmpty {
//             print("  no roots")
//             return
//         }

//         for root in rootConcepts {
//             var visited = Set<String>()

//             renderPresentationNode(
//                 locatorLabel: root,
//                 link: link,
//                 labelsByConcept: labelsByConcept,
//                 factsByConcept: factsByConcept,
//                 orderedChildrenByParent: orderedChildrenByParent,
//                 source: source,
//                 indent: 0,
//                 visited: &visited
//             )
//         }
//     }
// }

// private extension TaxonomyShared {
//     static func orderedChildrenByParent(
//         _ link: TaxonomyPresentationLink
//     ) -> [String: [TaxonomyPresentationArc]] {
//         let grouped = Dictionary(grouping: link.arcs, by: \.parent)

//         var out: [String: [TaxonomyPresentationArc]] = [:]
//         for (parent, arcs) in grouped {
//             out[parent] = arcs.sorted { lhs, rhs in
//                 switch (lhs.order, rhs.order) {
//                 case let (l?, r?):
//                     if l == r {
//                         return lhs.child < rhs.child
//                     }

//                     return l < r

//                 case (.some, .none):
//                     return true

//                 case (.none, .some):
//                     return false

//                 case (.none, .none):
//                     return lhs.child < rhs.child
//                 }
//             }
//         }

//         return out
//     }

//     static func renderPresentationNode(
//         locatorLabel: String,
//         link: TaxonomyPresentationLink,
//         labelsByConcept: [String: String],
//         factsByConcept: [String: TaxonomyComputedFact],
//         orderedChildrenByParent: [String: [TaxonomyPresentationArc]],
//         indent: Int,
//         visited: inout Set<String>
//     ) {
//         guard !visited.contains(locatorLabel) else {
//             return
//         }

//         visited.insert(locatorLabel)

//         guard let href = link.locators[locatorLabel] else {
//             return
//         }

//         let concept = conceptName(from: href)
//         let label = labelsByConcept[concept] ?? concept
//         let prefix = String(repeating: "    ", count: indent)

//         if let fact = factsByConcept[concept] {
//             print("\(prefix)\(label) = \(decimalString(fact.amount))")
//         } else {
//             print("\(prefix)\(label)")
//         }

//         for arc in orderedChildrenByParent[locatorLabel] ?? [] {
//             renderPresentationNode(
//                 locatorLabel: arc.child,
//                 link: link,
//                 labelsByConcept: labelsByConcept,
//                 factsByConcept: factsByConcept,
//                 orderedChildrenByParent: orderedChildrenByParent,
//                 indent: indent + 1,
//                 visited: &visited
//             )
//         }
//     }

//     static func renderPresentationNode(
//         locatorLabel: String,
//         link: TaxonomyPresentationLink,
//         labelsByConcept: [String: String],
//         factsByConcept: [String: [TaxonomyComputedMappedFact]],
//         orderedChildrenByParent: [String: [TaxonomyPresentationArc]],
//         source: TaxonomySourceData,
//         indent: Int,
//         visited: inout Set<String>
//     ) {
//         guard !visited.contains(locatorLabel) else {
//             return
//         }

//         visited.insert(locatorLabel)

//         guard let href = link.locators[locatorLabel] else {
//             return
//         }

//         let concept = conceptName(from: href)
//         let label = labelsByConcept[concept] ?? concept
//         let prefix = String(repeating: "    ", count: indent)

//         if let facts = factsByConcept[concept], !facts.isEmpty {
//             let total = facts.reduce(Decimal.zero) { partial, fact in
//                 partial + fact.amount
//             }

//             if let summary = summarizedPresentationDimensions(facts, source: source) {
//                 print("\(prefix)\(label) = \(decimalString(total)) :: \(summary)")
//             } else {
//                 print("\(prefix)\(label) = \(decimalString(total))")
//             }
//         } else {
//             print("\(prefix)\(label)")
//         }

//         for arc in orderedChildrenByParent[locatorLabel] ?? [] {
//             renderPresentationNode(
//                 locatorLabel: arc.child,
//                 link: link,
//                 labelsByConcept: labelsByConcept,
//                 factsByConcept: factsByConcept,
//                 orderedChildrenByParent: orderedChildrenByParent,
//                 source: source,
//                 indent: indent + 1,
//                 visited: &visited
//             )
//         }
//     }
// }
