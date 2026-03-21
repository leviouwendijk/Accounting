import Foundation

extension TaxonomyShared {
    public static func normalizedMappingSourceIdentifier(
        _ value: String
    ) -> String {
        trim(value)
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "_", with: "")
            .lowercased()
    }

    public static func canonicalizeMappings(
        _ mappings: [TaxonomyResolvedMapping],
        accounts: [String]
    ) -> [TaxonomyCanonicalResolvedMapping] {
        let accountsByNormalizedIdentifier = Dictionary(
            uniqueKeysWithValues: accounts.map {
                (normalizedMappingSourceIdentifier($0), $0)
            }
        )

        var out: [TaxonomyCanonicalResolvedMapping] = []

        for mapping in mappings {
            let normalizedSource = normalizedMappingSourceIdentifier(
                mapping.sourceIdentifier
            )

            let matchedCode =
                mapping.matchedCode
                ?? accountsByNormalizedIdentifier[normalizedSource]

            guard let matchedCode else {
                continue
            }

            out.append(
                TaxonomyCanonicalResolvedMapping(
                    sourceIdentifier: mapping.sourceIdentifier,
                    matchedCode: matchedCode,
                    targetConcept: mapping.targetConcept,
                    dimensions: mapping.dimensions
                )
            )
        }

        return out
    }

    public static func sortDimensions(
        _ dimensions: [TaxonomyDimensionBinding]
    ) -> [TaxonomyDimensionBinding] {
        dimensions.sorted {
            if $0.axis == $1.axis {
                return $0.member < $1.member
            }

            return $0.axis < $1.axis
        }
    }

    public static func factKey(
        from fact: TaxonomyComputedMappedFact
    ) -> TaxonomyMappedFactKey {
        TaxonomyMappedFactKey(
            concept: fact.concept,
            dimensions: sortDimensions(fact.dimensions)
        )
    }
}
