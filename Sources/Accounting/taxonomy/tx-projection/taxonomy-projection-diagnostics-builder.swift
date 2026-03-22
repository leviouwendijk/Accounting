import Foundation

public enum TaxonomyProjectionDiagnosticsBuilder {
    public static func build(
        bootstrap: LoadedTaxonomy,
        genericMapping: LoadedTaxonomyGenericMapping,
        presentation: [String],
        currentBalances: [String: Decimal]
    ) -> TaxonomyProjectionDiagnostics {
        let accountLookup = TaxonomyProjection.makeAccountLookup(
            identifiers: Array(currentBalances.keys),
            codes: Array(currentBalances.keys)
        )

        let canonicalMappings = TaxonomyProjection.canonicalizeMappings(
            genericMapping.resolvedMappings,
            lookup: accountLookup
        )

        let factsByKey = TaxonomyProjection.compileMappedFacts(
            mappings: canonicalMappings,
            rgsBalances: currentBalances
        )

        let flattenedFacts = TaxonomyProjection.projectMappedFactsToConceptFacts(
            factsByKey
        )

        let unmatched = TaxonomyProjection.unmatchedRGSCodes(
            mappings: canonicalMappings,
            rgsBalances: currentBalances
        )

        let nonZeroNativeBalances = currentBalances
            .filter { $0.value != 0 }
            .sorted { lhs, rhs in
                lhs.key < rhs.key
            }
            .map { pair in
                (code: pair.key, amount: pair.value)
            }

        let computedConceptTotals = Dictionary(
            uniqueKeysWithValues: flattenedFacts
                .map { pair in
                    (pair.key, pair.value.amount)
                }
                .sorted { lhs, rhs in
                    lhs.0 < rhs.0
                }
        )

        let computedConceptNames = Set(flattenedFacts.keys)

        let renderedConceptNames = Set(
            bootstrap.selectedPresentationLinks
                .flatMap { link in
                    link.locators.values.compactMap { href in
                        let concept = TaxonomyShared.normalizedTaxonomyConceptKey(
                            TaxonomyShared.conceptName(from: href)
                        )

                        return concept.isEmpty ? nil : concept
                    }
                }
        )

        let computedButNotRenderedConcepts = computedConceptNames
            .subtracting(renderedConceptNames)
            .sorted()

        let renderedWithoutComputedFacts = renderedConceptNames
            .subtracting(computedConceptNames)
            .sorted()

        let duplicateSourceExpansions = duplicateSourceExpansions(
            canonicalMappings: canonicalMappings
        )

        let unmatchedRGSCodes = unmatched
            .sorted()
            .map { code in
                (
                    code: code,
                    amount: currentBalances[code] ?? 0
                )
            }

        return TaxonomyProjectionDiagnostics(
            selectedPresentations: presentation,
            rankedGenericMappingCandidates: genericMapping.rankedCandidates,
            selectedGenericMappingEntrypointPath: genericMapping.selectedEntrypointPath,
            mappingEntryPaths: genericMapping.mappingEntryPaths,
            mappingDiagnostics: genericMapping.diagnostics,
            nonZeroNativeBalances: nonZeroNativeBalances,
            resolvedMappings: genericMapping.resolvedMappings,
            canonicalMappings: canonicalMappings,
            unmatchedRGSCodes: unmatchedRGSCodes,
            computedFactsByKeyCount: factsByKey.count,
            computedConceptTotals: computedConceptTotals,
            computedButNotRenderedConcepts: computedButNotRenderedConcepts,
            renderedWithoutComputedFacts: renderedWithoutComputedFacts,
            duplicateSourceExpansions: duplicateSourceExpansions
        )
    }

    private static func duplicateSourceExpansions(
        canonicalMappings: [TaxonomyCanonicalResolvedMapping]
    ) -> [TaxonomySourceExpansion] {
        let grouped = Dictionary(
            grouping: canonicalMappings,
            by: { mapping in
                mapping.sourceIdentifier
            }
        )

        return grouped.compactMap { sourceIdentifier, mappings in
            let targets = Array(
                Set(
                    mappings.map { mapping in
                        mapping.targetConcept
                    }
                )
            )
            .sorted()

            guard targets.count > 1 else {
                return nil
            }

            return TaxonomySourceExpansion(
                sourceIdentifier: sourceIdentifier,
                targets: targets
            )
        }.sorted { lhs, rhs in
            lhs.sourceIdentifier < rhs.sourceIdentifier
        }
    }
}
