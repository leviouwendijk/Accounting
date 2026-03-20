import Foundation

extension TaxonomyProbe {
    static func renderPresentationLink(
        _ link: PresentationLink,
        labelsByConcept: [String: String],
        factsByConcept: [String: ComputedFact]
    ) {
        var childrenByFrom: [String: [(Double, String)]] = [:]
        var allFrom: Set<String> = []
        var allTo: Set<String> = []

        for arc in link.arcs {
            childrenByFrom[arc.from, default: []].append((arc.order, arc.to))
            allFrom.insert(arc.from)
            allTo.insert(arc.to)
        }

        let rootLabels = allFrom.subtracting(allTo).sorted()

        func printNode(_ locatorLabel: String, indent: Int, seen: inout Set<String>) {
            guard let href = link.locs[locatorLabel] else {
                return
            }

            let concept = conceptName(from: href)
            let label = labelsByConcept[concept]
            let prefix = String(repeating: " ", count: indent)

            if let fact = factsByConcept[concept] {
                if let label {
                    print("\(prefix)- \(concept) — \(label) = \(decimalString(fact.amount))")
                } else {
                    print("\(prefix)- \(concept) = \(decimalString(fact.amount))")
                }

                if !fact.matchedCodes.isEmpty {
                    print("\(prefix)  matched: \(fact.matchedCodes.joined(separator: ", "))")
                }
            } else {
                if let label {
                    print("\(prefix)- \(concept) — \(label)")
                } else {
                    print("\(prefix)- \(concept)")
                }
            }

            if seen.contains(locatorLabel) {
                print("\(prefix)  [cycle detected]")
                return
            }

            seen.insert(locatorLabel)

            let children = (childrenByFrom[locatorLabel] ?? [])
                .sorted { lhs, rhs in
                    if lhs.0 == rhs.0 {
                        return lhs.1 < rhs.1
                    }
                    return lhs.0 < rhs.0
                }
                .map(\.1)

            for child in children {
                printNode(child, indent: indent + 4, seen: &seen)
            }

            seen.remove(locatorLabel)
        }

        print("role: \(link.role)")
        print("roots: \(rootLabels.count)")

        for root in rootLabels {
            var seen: Set<String> = []
            printNode(root, indent: 0, seen: &seen)
        }
    }
}
