import Foundation

extension TaxonomyProberRunner {
    public func runCSVMapping(
        zipFileURL: URL,
        bootstrap: TaxonomyProbeBootstrap
    ) throws {
        let extracted = try extractMatchingMappingCSV(
            zipFileURL: zipFileURL,
            entrypointBasename: bootstrap.entrypointBasename,
            source: config.source
        )

        print("resolved mapping csv entry:")
        print("  \(extracted.entryPath)")
        print("")

        let mappingFile = try TaxonomyCSVParser.parseMappingCSV(
            extracted.csv
        )

        print("mapping csv:")
        print("  header columns: \(mappingFile.header.count)")
        print("  rows: \(mappingFile.rows.count)")
        print("")

        let factsByKey = compileFactsKeepingDimensions(
            mappingRows: mappingFile.rows,
            rgsBalances: config.demoRGSBalances
        )

        let factsByConcept = groupMappedFactsByConceptKeepingDimensions(
            factsByKey
        )

        let flattenedFacts = projectMappedFactsToConceptFacts(
            factsByKey
        )

        renderComputedMappedFacts(
            factsByKey,
            limit: 200
        )
        print("")

        for link in bootstrap.selectedLinks {
            renderPresentationLink(
                link,
                labelsByConcept: bootstrap.labelsByConcept,
                factsByConcept: flattenedFacts
            )
            print("")
        }

        print("dimensional presentation view:")
        for link in bootstrap.selectedLinks {
            renderPresentationLink(
                link,
                labelsByConcept: bootstrap.labelsByConcept,
                factsByConcept: factsByConcept,
                source: config.source
            )
            print("")
        }
    }
}
