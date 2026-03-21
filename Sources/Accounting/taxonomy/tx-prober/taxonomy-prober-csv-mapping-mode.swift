import Foundation

extension TaxonomyProberRunner {
    public func runCSVMapping(
        zipFileURL: URL,
        bootstrap: LoadedTaxonomy
    ) throws {
        let loadedMapping = try TaxonomyLoader.loadCSVMapping(
            zipFileURL: zipFileURL,
            taxonomy: bootstrap
        )

        print("resolved mapping csv entry:")
        print("  \(loadedMapping.entryPath)")
        print("")
        print("mapping csv:")
        print("  header columns: \(loadedMapping.mappingFile.header.count)")
        print("  rows: \(loadedMapping.mappingFile.rows.count)")
        print("")

        let factsByKey = TaxonomyProjection.compileFactsKeepingDimensions(
            mappingRows: loadedMapping.mappingFile.rows,
            rgsBalances: config.demoRGSBalances
        )

        let factsByConcept = TaxonomyProjection.groupMappedFactsByConceptKeepingDimensions(
            factsByKey
        )

        let flattenedFacts = TaxonomyProjection.projectMappedFactsToConceptFacts(
            factsByKey
        )

        TaxonomyShared.renderComputedMappedFacts(
            factsByKey,
            limit: 200
        )
        print("")

        for link in bootstrap.selectedPresentationLinks {
            TaxonomyShared.renderPresentationLink(
                link,
                labelsByConcept: bootstrap.labelsByConcept,
                factsByConcept: flattenedFacts
            )
            print("")
        }

        print("dimensional presentation view:")
        for link in bootstrap.selectedPresentationLinks {
            TaxonomyShared.renderPresentationLink(
                link,
                labelsByConcept: bootstrap.labelsByConcept,
                factsByConcept: factsByConcept,
                source: config.source
            )
            print("")
        }
    }
}
