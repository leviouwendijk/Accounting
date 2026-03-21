import Foundation

extension TaxonomyShared {
    public static func renderResolvedMappings(
        _ mappings: [TaxonomyResolvedMapping],
        limit: Int = 500
    ) {
        print("resolved mappings:")

        if mappings.isEmpty {
            print("  none")
            return
        }

        for mapping in mappings.prefix(limit) {
            let dimensionSuffix = renderExplicitDimensions(mapping.dimensions)

            print("  href: \(mapping.sourceHref)")
            print("    locator: \(mapping.sourceLocatorLabel)")
            print("    sourceIdentifier: \(mapping.sourceIdentifier)")
            print("    datapoint: \(mapping.targetDatapointLabel)")
            print("    target: \(mapping.targetConcept)\(dimensionSuffix)")
        }

        if mappings.count > limit {
            print("  ... +\(mappings.count - limit) more")
        }
    }

    public static func renderComputedMappedFacts(
        _ factsByKey: [TaxonomyMappedFactKey: TaxonomyComputedMappedFact],
        limit: Int = 500
    ) {
        print("computed mapped facts:")

        let facts = factsByKey.values.sorted { lhs, rhs in
            if lhs.concept == rhs.concept {
                let lhsDimensions = lhs.dimensions.map { "\($0.axis)=\($0.member)" }
                let rhsDimensions = rhs.dimensions.map { "\($0.axis)=\($0.member)" }

                if lhsDimensions == rhsDimensions {
                    return lhs.amount < rhs.amount
                }

                return lhsDimensions.lexicographicallyPrecedes(rhsDimensions)
            }

            return lhs.concept < rhs.concept
        }

        if facts.isEmpty {
            print("  none")
            return
        }

        for fact in facts.prefix(limit) {
            let dimensionSuffix = renderBoundDimensions(fact.dimensions)
            let sourceSuffix: String

            if fact.sourceCodes.isEmpty {
                sourceSuffix = ""
            } else {
                sourceSuffix = " :: " + fact.sourceCodes.joined(separator: ", ")
            }

            print(
                "  \(fact.concept)\(dimensionSuffix) = \(decimalString(fact.amount))\(sourceSuffix)"
            )
        }

        if facts.count > limit {
            print("  ... +\(facts.count - limit) more")
        }
    }

    public static func renderCanonicalMappings(
        mappings: [TaxonomyCanonicalResolvedMapping],
        prefix: String? = nil,
        limit: Int = 200
    ) {
        print("canonical mappings:")

        let filtered = mappings
            .filter { mapping in
                guard let prefix else {
                    return true
                }

                return mapping.matchedCode.hasPrefix(prefix)
            }
            .sorted { lhs, rhs in
                if lhs.matchedCode == rhs.matchedCode {
                    return lhs.targetConcept < rhs.targetConcept
                }

                return lhs.matchedCode < rhs.matchedCode
            }

        if filtered.isEmpty {
            print("  none")
            return
        }

        for mapping in filtered.prefix(limit) {
            let dimensionSuffix = renderExplicitDimensions(mapping.dimensions)
            print(
                "  \(mapping.matchedCode) -> \(mapping.targetConcept)\(dimensionSuffix) [source: \(mapping.sourceIdentifier)]"
            )
        }

        if filtered.count > limit {
            print("  ... +\(filtered.count - limit) more")
        }
    }

    public static func renderMappingResolutionDiagnostics(
        _ diagnostics: TaxonomyMappingResolutionDiagnostics,
        indent: String = "  "
    ) {
        print("mapping resolution diagnostics:")
        print("\(indent)total datapoints: \(diagnostics.totalDatapoints)")
        print("\(indent)resolved: \(diagnostics.resolvedCount)")
        print("\(indent)unresolved: \(diagnostics.unresolvedCount)")

        if !diagnostics.unresolvedConceptSamples.isEmpty {
            print("\(indent)unresolved samples:")
            for sample in diagnostics.unresolvedConceptSamples {
                print("\(indent)  \(sample)")
            }
        }
    }
}

private extension TaxonomyShared {
    static func renderExplicitDimensions(
        _ dimensions: [TaxonomyExplicitDimension]
    ) -> String {
        guard !dimensions.isEmpty else {
            return ""
        }

        let rendered = dimensions.map {
            "\($0.axis)=\($0.member)"
        }.joined(separator: ", ")

        return " [\(rendered)]"
    }

    static func renderBoundDimensions(
        _ dimensions: [TaxonomyDimensionBinding]
    ) -> String {
        guard !dimensions.isEmpty else {
            return ""
        }

        let rendered = dimensions.map {
            "\($0.axis)=\($0.member)"
        }.joined(separator: ", ")

        return " [\(rendered)]"
    }
}
