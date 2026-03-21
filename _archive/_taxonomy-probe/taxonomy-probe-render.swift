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

    public static func renderCanonicalMappings(
        mappings: [CanonicalResolvedMapping],
        prefix: String,
        limit: Int = 200
    ) {
        let filtered = mappings
            .filter { $0.sourceCode.hasPrefix(prefix) }
            .sorted { lhs, rhs in
                if lhs.sourceCode == rhs.sourceCode {
                    if lhs.targetPrimaryQName == rhs.targetPrimaryQName {
                        let lhsDims = lhs.dimensions
                            .map { dim in
                                if let member = dim.member, !member.isEmpty {
                                    return "\(dim.qname)=\(member)"
                                } else {
                                    return dim.qname
                                }
                            }
                            .sorted()
                            .joined(separator: "|")

                        let rhsDims = rhs.dimensions
                            .map { dim in
                                if let member = dim.member, !member.isEmpty {
                                    return "\(dim.qname)=\(member)"
                                } else {
                                    return dim.qname
                                }
                            }
                            .sorted()
                            .joined(separator: "|")

                        return lhsDims < rhsDims
                    }

                    return lhs.targetPrimaryQName < rhs.targetPrimaryQName
                }

                return lhs.sourceCode < rhs.sourceCode
            }

        print("canonical mappings with prefix \(prefix): \(filtered.count)")

        for mapping in filtered.prefix(limit) {
            let dims = mapping.dimensions
                .map { dim in
                    if let member = dim.member, !member.isEmpty {
                        return "\(dim.qname)=\(member)"
                    } else {
                        return dim.qname
                    }
                }
                .sorted()

            if dims.isEmpty {
                print("  \(mapping.sourceCode) -> \(mapping.targetPrimaryQName)")
            } else {
                print("  \(mapping.sourceCode) -> \(mapping.targetPrimaryQName) [\(dims.joined(separator: ", "))]")
            }
        }

        if filtered.count > limit {
            print("  ... \(filtered.count - limit) more")
        }

        print("")
    }
}

extension TaxonomyProbe {
    public static func summarizedPresentationDimensions(
        _ dimensions: [DimensionBinding],
        source: TaxonomySourceData? = nil
    ) -> String {
        let parts = sortDimensions(dimensions).compactMap { dimension -> String? in
            if let source {
                return source.summarizePresentationDimension(dimension)
            }

            return TaxonomySourceData.summarizePresentationDimensionDefault(dimension)
        }

        return parts.joined(separator: ", ")
    }

    public static func renderPresentationLink(
        _ link: PresentationLink,
        labelsByConcept: [String: String],
        factsByConcept: [String: [ComputedMappedFact]],
        source: TaxonomySourceData? = nil
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

        func printFactVariants(
            _ facts: [ComputedMappedFact],
            prefix: String
        ) {
            for fact in facts {
                let dims = summarizedPresentationDimensions(
                    fact.key.dimensions,
                    source: source
                )
                let matched = Array(Set(fact.matchedCodes)).sorted()

                if dims.isEmpty {
                    print("\(prefix)  = \(decimalString(fact.amount))")
                } else {
                    print("\(prefix)  [\(dims)] = \(decimalString(fact.amount))")
                }

                if !matched.isEmpty {
                    print("\(prefix)    matched: \(matched.joined(separator: ", "))")
                }
            }
        }

        func printNode(_ locatorLabel: String, indent: Int, seen: inout Set<String>) {
            guard let href = link.locs[locatorLabel] else {
                return
            }

            let concept = TaxonomyProbe.normalizedTaxonomyConceptKey(
                conceptName(from: href)
            )
            let label = labelsByConcept[concept]
            let prefix = String(repeating: " ", count: indent)

            if let facts = factsByConcept[concept], !facts.isEmpty {
                if let label {
                    print("\(prefix)- \(concept) — \(label)")
                } else {
                    print("\(prefix)- \(concept)")
                }

                printFactVariants(facts, prefix: prefix)
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

extension TaxonomyProbe {
    public static func renderMappingResolutionDiagnostics(
        _ diagnostics: MappingResolutionDiagnostics,
        indent: String = ""
    ) {
        print("\(indent)mapping diagnostics:")
        print("\(indent)  arcs seen: \(diagnostics.totalArcs)")
        print("\(indent)  resolved mappings: \(diagnostics.resolvedMappings)")
        print("\(indent)  dropped missing locator: \(diagnostics.droppedMissingLocator)")
        print("\(indent)  dropped missing datapoint: \(diagnostics.droppedMissingDatapoint)")
        print("\(indent)  dropped missing primary qname: \(diagnostics.droppedMissingPrimaryQName)")
        print("\(indent)  dropped missing source concept: \(diagnostics.droppedMissingSourceConcept)")
        print("\(indent)  source concept via url fragment: \(diagnostics.sourceConceptFromURLFragment)")
        print("\(indent)  source concept via raw hash fragment: \(diagnostics.sourceConceptFromRawHashFragment)")
        print("\(indent)  source concept via whole-href fallback: \(diagnostics.sourceConceptFromFallbackWholeHref)")
        print("\(indent)  source concept via empty href: \(diagnostics.sourceConceptFromEmptyHref)")

        if !diagnostics.arcroles.isEmpty {
            print("\(indent)  arcroles:")
            for key in diagnostics.arcroles.keys.sorted() {
                print("\(indent)    \(key): \(diagnostics.arcroles[key] ?? 0)")
            }
        }

        if !diagnostics.sampleMissingLocatorLabels.isEmpty {
            print("\(indent)  sample missing locator labels: \(diagnostics.sampleMissingLocatorLabels.joined(separator: ", "))")
        }

        if !diagnostics.sampleMissingDatapointLabels.isEmpty {
            print("\(indent)  sample missing datapoint labels: \(diagnostics.sampleMissingDatapointLabels.joined(separator: ", "))")
        }

        if !diagnostics.sampleMissingPrimaryQNameDatapoints.isEmpty {
            print("\(indent)  sample datapoints missing primary qname: \(diagnostics.sampleMissingPrimaryQNameDatapoints.joined(separator: ", "))")
        }

        if !diagnostics.sampleFallbackSourceHrefs.isEmpty {
            print("\(indent)  sample fallback source hrefs:")
            for href in diagnostics.sampleFallbackSourceHrefs {
                print("\(indent)    \(href)")
            }
        }
    }
}
