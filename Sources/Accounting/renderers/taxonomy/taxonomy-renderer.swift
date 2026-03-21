import Foundation

public enum TaxonomyRenderer {
    public static func render(
        _ output: TaxonomyCompileProjectionOutput
    ) {
        TaxonomyShared.renderResolvedMappings(
            output.resolvedMappings,
            limit: 1000
        )
        print("")

        TaxonomyShared.renderCanonicalMappings(
            mappings: output.canonicalMappings,
            limit: 1000
        )
        print("")

        TaxonomyShared.renderComputedMappedFacts(
            output.factsByKey,
            limit: 1000
        )
        print("")

        TaxonomyShared.renderUsedProjectCoverage(
            mappings: output.canonicalMappings,
            balances: output.balances
        )
        print("")

        for link in output.bootstrap.selectedPresentationLinks {
            TaxonomyShared.renderPresentationLink(
                link,
                labelsByConcept: output.bootstrap.labelsByConcept,
                factsByConcept: output.flattenedFacts
            )
            print("")
        }

        print("dimensional presentation view:")
        for link in output.bootstrap.selectedPresentationLinks {
            TaxonomyShared.renderPresentationLink(
                link,
                labelsByConcept: output.bootstrap.labelsByConcept,
                factsByConcept: output.factsByConcept,
                source: output.bootstrap.source
            )
            print("")
        }
    }

    public static func render(
        _ output: TaxonomyPeriodProjectionOutput,
        comparePrevious: Bool
    ) {
        print(output.currentRange.string())
        print("")

        for link in output.bootstrap.selectedPresentationLinks {
            TaxonomyShared.renderPresentationLink(
                link,
                labelsByConcept: output.bootstrap.labelsByConcept,
                factsByConcept: output.currentFlattenedFacts
            )
            print("")
        }

        print("dimensional presentation view:")
        for link in output.bootstrap.selectedPresentationLinks {
            TaxonomyShared.renderPresentationLink(
                link,
                labelsByConcept: output.bootstrap.labelsByConcept,
                factsByConcept: output.currentFactsByConcept,
                source: output.bootstrap.source
            )
            print("")
        }

        guard comparePrevious,
              let previousRange = output.previousRange,
              let previousFlattenedFacts = output.previousFlattenedFacts,
              let previousFactsByConcept = output.previousFactsByConcept
        else {
            return
        }

        print("")
        print(previousRange.string())
        print("")

        for link in output.bootstrap.selectedPresentationLinks {
            TaxonomyShared.renderPresentationLink(
                link,
                labelsByConcept: output.bootstrap.labelsByConcept,
                factsByConcept: previousFlattenedFacts
            )
            print("")
        }

        print("dimensional presentation view:")
        for link in output.bootstrap.selectedPresentationLinks {
            TaxonomyShared.renderPresentationLink(
                link,
                labelsByConcept: output.bootstrap.labelsByConcept,
                factsByConcept: previousFactsByConcept,
                source: output.bootstrap.source
            )
            print("")
        }
    }
}
