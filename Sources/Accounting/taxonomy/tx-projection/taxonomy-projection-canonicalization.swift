import Foundation

extension TaxonomyProjection {
    public static func normalizedMappingSourceIdentifier(
        _ value: String
    ) -> String {
        var out = TaxonomyShared.trim(value)

        if out.hasPrefix("rgs-i_") {
            out = String(out.dropFirst("rgs-i_".count))
        } else if out.hasPrefix("rgs-k_") {
            out = String(out.dropFirst("rgs-k_".count))
        }

        return out
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "_", with: "")
            .lowercased()
    }

    public static func canonicalizeMappings(
        _ mappings: [TaxonomyResolvedMapping],
        lookup: TaxonomyAccountLookup
    ) -> [TaxonomyCanonicalResolvedMapping] {
        var out: [TaxonomyCanonicalResolvedMapping] = []

        for mapping in mappings {
            let normalizedSource = normalizedMappingSourceIdentifier(
                mapping.sourceIdentifier
            )

            let matchedCode =
                mapping.matchedCode
                ?? lookup.byIdentifier[normalizedSource]
                ?? lookup.byCode[normalizedSource]

            // for mapping in mappings.prefix(50) {
                // let normalizedSource = normalizedMappingSourceIdentifier(
                //     mapping.sourceIdentifier
                // )

                // let identifierHit = lookup.byIdentifier[normalizedSource]
                // let codeHit = lookup.byCode[normalizedSource]

                // DEBUG:
                // print("canonicalization sample:")
                // print("  sourceHref: \(mapping.sourceHref)")
                // print("  sourceIdentifier: \(mapping.sourceIdentifier)")
                // print("  normalized: \(normalizedSource)")
                // print("  identifierHit: \(identifierHit ?? "nil")")
                // print("  codeHit: \(codeHit ?? "nil")")
                // print("  targetConcept: \(mapping.targetConcept)")
            // }

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

extension TaxonomyProjection {
    public static func makeAccountLookup(
        identifiers: [String],
        codes: [String]
    ) -> TaxonomyAccountLookup {
        var byIdentifier: [String: String] = [:]
        var byCode: [String: String] = [:]

        for identifier in identifiers {
            let normalized = normalizedMappingSourceIdentifier(identifier)
            if byIdentifier[normalized] == nil {
                byIdentifier[normalized] = identifier
            }
        }

        for code in codes {
            let normalized = normalizedMappingSourceIdentifier(code)
            if byCode[normalized] == nil {
                byCode[normalized] = code
            }
        }

        return TaxonomyAccountLookup(
            byIdentifier: byIdentifier,
            byCode: byCode
        )
    }
}
