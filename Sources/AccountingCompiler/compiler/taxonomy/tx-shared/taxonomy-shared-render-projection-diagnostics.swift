import Accounting
import Foundation

extension TaxonomyShared {
    public static func renderProjectionDiagnostics(
        _ diagnostics: TaxonomyProjectionDiagnostics,
        limit: Int = 100
    ) {
        print("taxonomy projection diagnostics:")
        print("")

        print("selected presentations:")
        if diagnostics.selectedPresentations.isEmpty {
            print("  profile defaults")
        } else {
            for value in diagnostics.selectedPresentations {
                print("  \(value)")
            }
        }
        print("")

        print("generic mapping candidates:")
        if diagnostics.rankedGenericMappingCandidates.isEmpty {
            print("  none")
        } else {
            for candidate in diagnostics.rankedGenericMappingCandidates.prefix(limit) {
                print("  \(candidate)")
            }

            if diagnostics.rankedGenericMappingCandidates.count > limit {
                print("  ... +\(diagnostics.rankedGenericMappingCandidates.count - limit) more")
            }
        }
        print("")

        print("selected generic mapping entrypoint:")
        if let path = diagnostics.selectedGenericMappingEntrypointPath {
            print("  \(path)")
        } else {
            print("  none")
        }
        print("")

        print("resolved mapping XML entries:")
        if diagnostics.mappingEntryPaths.isEmpty {
            print("  none")
        } else {
            for path in diagnostics.mappingEntryPaths {
                print("  \(path)")
            }
        }
        print("")

        if diagnostics.mappingDiagnostics.isEmpty {
            print("mapping diagnostics:")
            print("  none")
            print("")
        } else {
            let orderedPaths = diagnostics.mappingDiagnostics.keys.sorted()

            for path in orderedPaths {
                guard let entry = diagnostics.mappingDiagnostics[path] else {
                    continue
                }

                print("mapping diagnostics for: \(path)")
                print("  total datapoints: \(entry.totalDatapoints)")
                print("  resolved: \(entry.resolvedCount)")
                print("  unresolved: \(entry.unresolvedCount)")

                if entry.unresolvedConceptSamples.isEmpty {
                    print("  unresolved samples: none")
                } else {
                    print("  unresolved samples:")
                    for sample in entry.unresolvedConceptSamples.prefix(limit) {
                        print("    \(sample)")
                    }

                    if entry.unresolvedConceptSamples.count > limit {
                        print("    ... +\(entry.unresolvedConceptSamples.count - limit) more")
                    }
                }

                print("")
            }
        }

        print("non-zero native balances: \(diagnostics.nonZeroNativeBalances.count)")
        for item in diagnostics.nonZeroNativeBalances.prefix(limit) {
            print("  \(item.code): \(decimalString(item.amount))")
        }
        if diagnostics.nonZeroNativeBalances.count > limit {
            print("  ... +\(diagnostics.nonZeroNativeBalances.count - limit) more")
        }
        print("")

        print("resolved mappings: \(diagnostics.resolvedMappings.count)")
        print("canonical mappings: \(diagnostics.canonicalMappings.count)")
        print("computed fact keys: \(diagnostics.computedFactsByKeyCount)")
        print("computed concept totals: \(diagnostics.computedConceptTotals.count)")
        print("")

        print("unmatched non-zero RGS balances: \(diagnostics.unmatchedRGSCodes.count)")
        if diagnostics.unmatchedRGSCodes.isEmpty {
            print("  none")
        } else {
            for item in diagnostics.unmatchedRGSCodes.prefix(limit) {
                print("  \(item.code): \(decimalString(item.amount))")
            }

            if diagnostics.unmatchedRGSCodes.count > limit {
                print("  ... +\(diagnostics.unmatchedRGSCodes.count - limit) more")
            }
        }
        print("")

        print("duplicate source expansions: \(diagnostics.duplicateSourceExpansions.count)")
        if diagnostics.duplicateSourceExpansions.isEmpty {
            print("  none")
        } else {
            for item in diagnostics.duplicateSourceExpansions.prefix(limit) {
                print("  \(item.sourceIdentifier)")
                for target in item.targets {
                    print("    -> \(target)")
                }
            }

            if diagnostics.duplicateSourceExpansions.count > limit {
                print("  ... +\(diagnostics.duplicateSourceExpansions.count - limit) more")
            }
        }
        print("")

        print("computed but not rendered concepts: \(diagnostics.computedButNotRenderedConcepts.count)")
        if diagnostics.computedButNotRenderedConcepts.isEmpty {
            print("  none")
        } else {
            for concept in diagnostics.computedButNotRenderedConcepts.prefix(limit) {
                print("  \(concept)")
            }

            if diagnostics.computedButNotRenderedConcepts.count > limit {
                print("  ... +\(diagnostics.computedButNotRenderedConcepts.count - limit) more")
            }
        }
        print("")

        print("rendered without computed facts: \(diagnostics.renderedWithoutComputedFacts.count)")
        if diagnostics.renderedWithoutComputedFacts.isEmpty {
            print("  none")
        } else {
            for concept in diagnostics.renderedWithoutComputedFacts.prefix(limit) {
                print("  \(concept)")
            }

            if diagnostics.renderedWithoutComputedFacts.count > limit {
                print("  ... +\(diagnostics.renderedWithoutComputedFacts.count - limit) more")
            }
        }
        print("")
    }
}
