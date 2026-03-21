import Foundation

public enum TaxonomyRenderer {
    public static func render(
        _ output: TaxonomyCompileProjectionOutput,
        options: TaxonomyRenderOptions = .init()
    ) {
        renderCompileDiagnostics(
            output,
            options: options
        )

        renderCompileMainView(
            output,
            options: options
        )

        if options.showDimensionalPresentation,
           options.defaultView != .dimensional {
            print("dimensional presentation view:")
            for link in output.bootstrap.selectedPresentationLinks {
                TaxonomyShared.renderPresentationLink(
                    link,
                    labelsByConcept: output.bootstrap.labelsByConcept,
                    factsByConcept: output.flattenedFacts,
                    pruneEmpty: options.pruneEmptyPresentationBranches
                )
                print("")
            }
        }
    }

    public static func render(
        _ output: TaxonomyPeriodProjectionOutput,
        options: TaxonomyRenderOptions = .init()
    ) {
        print(output.currentRange.string())
        print("")

        renderPeriodMainView(
            flattenedFacts: output.currentFlattenedFacts,
            factsByConcept: output.currentFactsByConcept,
            bootstrap: output.bootstrap,
            options: options
        )

        if options.showDimensionalPresentation,
           options.defaultView != .dimensional {
            print("dimensional presentation view:")
            for link in output.bootstrap.selectedPresentationLinks {
                TaxonomyShared.renderPresentationLink(
                    link,
                    labelsByConcept: output.bootstrap.labelsByConcept,
                    factsByConcept: output.currentFactsByConcept,
                    source: output.bootstrap.source,
                    pruneEmpty: options.pruneEmptyPresentationBranches
                )
                print("")
            }
        }

        guard options.comparePrevious,
              let previousRange = output.previousRange,
              let previousFlattenedFacts = output.previousFlattenedFacts,
              let previousFactsByConcept = output.previousFactsByConcept
        else {
            return
        }

        print("")
        print(previousRange.string())
        print("")

        renderPeriodMainView(
            flattenedFacts: previousFlattenedFacts,
            factsByConcept: previousFactsByConcept,
            bootstrap: output.bootstrap,
            options: options
        )

        if options.showDimensionalPresentation,
           options.defaultView != .dimensional {
            print("dimensional presentation view:")
            for link in output.bootstrap.selectedPresentationLinks {
                TaxonomyShared.renderPresentationLink(
                    link,
                    labelsByConcept: output.bootstrap.labelsByConcept,
                    factsByConcept: previousFactsByConcept,
                    source: output.bootstrap.source,
                    pruneEmpty: options.pruneEmptyPresentationBranches
                )
                print("")
            }
        }
    }

    private static func renderCompileDiagnostics(
        _ output: TaxonomyCompileProjectionOutput,
        options: TaxonomyRenderOptions
    ) {
        if options.showResolvedMappings {
            TaxonomyShared.renderResolvedMappings(
                output.resolvedMappings,
                limit: 1000
            )
            print("")
        }

        if options.showCanonicalMappings {
            TaxonomyShared.renderCanonicalMappings(
                mappings: output.canonicalMappings,
                limit: 1000
            )
            print("")
        }

        if options.showComputedMappedFacts {
            TaxonomyShared.renderComputedMappedFacts(
                output.factsByKey,
                limit: 1000
            )
            print("")
        }

        if options.showCoverage {
            TaxonomyShared.renderUsedProjectCoverage(
                mappings: output.canonicalMappings,
                balances: output.balances
            )
            print("")
        }
    }

    private static func renderCompileMainView(
        _ output: TaxonomyCompileProjectionOutput,
        options: TaxonomyRenderOptions
    ) {
        switch options.defaultView {
        case .presentation:
            for link in output.bootstrap.selectedPresentationLinks {
                TaxonomyShared.renderPresentationLink(
                    link,
                    labelsByConcept: output.bootstrap.labelsByConcept,
                    factsByConcept: output.flattenedFacts,
                    pruneEmpty: options.pruneEmptyPresentationBranches
                )
                print("")
            }

        case .flattened:
            TaxonomyShared.renderComputedFacts(
                output.flattenedFacts,
                limit: 1000
            )
            print("")

        case .dimensional:
            for link in output.bootstrap.selectedPresentationLinks {
                TaxonomyShared.renderPresentationLink(
                    link,
                    labelsByConcept: output.bootstrap.labelsByConcept,
                    factsByConcept: output.factsByConcept,
                    source: output.bootstrap.source,
                    pruneEmpty: options.pruneEmptyPresentationBranches
                )
                print("")
            }
        }
    }

    private static func renderPeriodMainView(
        flattenedFacts: [String: TaxonomyComputedFact],
        factsByConcept: [String: [TaxonomyComputedMappedFact]],
        bootstrap: LoadedTaxonomy,
        options: TaxonomyRenderOptions
    ) {
        switch options.defaultView {
        case .presentation:
            for link in bootstrap.selectedPresentationLinks {
                TaxonomyShared.renderPresentationLink(
                    link,
                    labelsByConcept: bootstrap.labelsByConcept,
                    factsByConcept: flattenedFacts,
                    pruneEmpty: options.pruneEmptyPresentationBranches
                )
                print("")
            }

        case .flattened:
            TaxonomyShared.renderComputedFacts(
                flattenedFacts,
                limit: 1000
            )
            print("")

        case .dimensional:
            for link in bootstrap.selectedPresentationLinks {
                TaxonomyShared.renderPresentationLink(
                    link,
                    labelsByConcept: bootstrap.labelsByConcept,
                    factsByConcept: factsByConcept,
                    source: bootstrap.source,
                    pruneEmpty: options.pruneEmptyPresentationBranches
                )
                print("")
            }
        }
    }
}
