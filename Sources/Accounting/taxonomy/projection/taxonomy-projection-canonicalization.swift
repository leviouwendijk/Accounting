import Foundation

extension TaxonomyProjection {
    public static func normalizedMappingSourceIdentifier(
        _ value: String
    ) -> String {
        TaxonomyShared.trim(value)
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

    public static func factKey(
        from fact: TaxonomyComputedMappedFact
    ) -> TaxonomyMappedFactKey {
        TaxonomyMappedFactKey(
            concept: fact.concept,
            dimensions: TaxonomyShared.sortDimensions(fact.dimensions)
        )
    }
}
