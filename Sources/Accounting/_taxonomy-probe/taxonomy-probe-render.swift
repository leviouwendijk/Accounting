import Foundation

extension TaxonomyProbe {
    public static func renderPresentationLink(
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

            let concept = TaxonomyProbe.normalizedTaxonomyConceptKey(
                conceptName(from: href)
            )
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

    public static func renderResolvedMappings(
        _ mappings: [ResolvedMapping],
        limit: Int = 80
    ) {
        print("resolved mappings: \(mappings.count)")

        for mapping in mappings.prefix(limit) {
            let dims = mapping.dimensions.map { dimension in
                if let member = dimension.member, !member.isEmpty {
                    return "\(dimension.qname)=\(member)"
                } else {
                    return dimension.qname
                }
            }

            if dims.isEmpty {
                print("  \(mapping.sourceConcept) -> \(mapping.targetPrimaryQName)")
            } else {
                print("  \(mapping.sourceConcept) -> \(mapping.targetPrimaryQName) [\(dims.joined(separator: ", "))]")
            }
        }

        if mappings.count > limit {
            print("  ... \(mappings.count - limit) more")
        }
    }
}

extension TaxonomyProbe {
    public static func renderComputedMappedFacts(
        _ factsByKey: [MappedFactKey: ComputedMappedFact],
        limit: Int = 120
    ) {
        let sorted = factsByKey.values.sorted { lhs, rhs in
            if lhs.key.concept == rhs.key.concept {
                let lhsDims = sortDimensions(lhs.key.dimensions)
                    .map { "\($0.qname)=\($0.member ?? "")" }
                    .joined(separator: "|")

                let rhsDims = sortDimensions(rhs.key.dimensions)
                    .map { "\($0.qname)=\($0.member ?? "")" }
                    .joined(separator: "|")

                return lhsDims < rhsDims
            }

            return lhs.key.concept < rhs.key.concept
        }

        print("computed mapped facts: \(sorted.count)")

        for fact in sorted.prefix(limit) {
            let dims = sortDimensions(fact.key.dimensions).map { dimension in
                if let member = dimension.member, !member.isEmpty {
                    return "\(dimension.qname)=\(member)"
                } else {
                    return dimension.qname
                }
            }

            if dims.isEmpty {
                print("  \(fact.key.concept) = \(decimalString(fact.amount))")
            } else {
                print("  \(fact.key.concept) [\(dims.joined(separator: ", "))] = \(decimalString(fact.amount))")
            }

            let matched = Array(Set(fact.matchedCodes)).sorted()
            if !matched.isEmpty {
                print("    matched: \(matched.joined(separator: ", "))")
            }
        }

        if sorted.count > limit {
            print("  ... \(sorted.count - limit) more")
        }
    }
}
