import Foundation

extension TaxonomyProberRunner {
    public func runGenericMappingInspection(
        zipFileURL: URL,
        bootstrap: LoadedTaxonomy
    ) throws {
        guard let chartFile = config.chartFile else {
            throw TaxonomyProbeError.missingChartFile
        }

        let chart = try TaxonomyProber.loadCompiledChart(
            from: chartFile
        )

        let accountCodes = chart.nodes.map(\.codes.code).filter { !$0.isEmpty }

        let loadedMapping = try TaxonomyLoader.loadGenericMapping(
            zipFileURL: zipFileURL,
            source: config.source,
            probeKeywords: config.probeKeywords
        )

        print("generic mapping candidates:")
        if loadedMapping.rankedCandidates.isEmpty {
            print("  none")
            return
        }

        for entry in loadedMapping.rankedCandidates.prefix(40) {
            let score = TaxonomyLoader.zipPathMatchScore(
                entry,
                keywords: config.probeKeywords,
                source: config.source
            )
            print("  [\(score)] \(entry)")
        }
        print("")

        print("selected generic mapping entry:")
        print("  \(loadedMapping.selectedEntryPath)")
        print("")

        let resolution = TaxonomyParser.resolveMappingsDetailed(
            from: loadedMapping.linkbase
        )

        let canonicalMappings = TaxonomyProjection.canonicalizeMappings(
            resolution.resolvedMappings,
            accounts: accountCodes
        )

        let balances: [String: Decimal]
        switch config.balanceInput {
        case .demo:
            balances = config.demoRGSBalances

        case .project:
            guard let projectRoot = config.projectRoot else {
                balances = [:]
                break
            }

            balances = TaxonomyTester.projectBalances(
                projectRoot: projectRoot
            )
        }

        let factsByKey = TaxonomyProjection.compileMappedFacts(
            mappings: canonicalMappings,
            rgsBalances: balances
        )

        let factsByConcept = TaxonomyProjection.groupMappedFactsByConceptKeepingDimensions(
            factsByKey
        )

        let flattenedFacts = TaxonomyProjection.projectMappedFactsToConceptFacts(
            factsByKey
        )

        TaxonomyShared.renderMappingResolutionDiagnostics(
            resolution.diagnostics
        )
        print("")

        TaxonomyShared.renderResolvedMappings(
            resolution.resolvedMappings,
            limit: 200
        )
        print("")

        TaxonomyShared.renderCanonicalMappings(
            mappings: canonicalMappings,
            limit: 200
        )
        print("")

        TaxonomyShared.renderComputedMappedFacts(
            factsByKey,
            limit: 200
        )
        print("")

        TaxonomyShared.renderDemoBalanceCoverage(
            mappings: canonicalMappings,
            rgsBalances: balances
        )
        print("")

        TaxonomyShared.renderUsedProjectCoverage(
            mappings: canonicalMappings,
            balances: balances
        )
        print("")

        let unmatched = TaxonomyProjection.unmatchedRGSCodes(
            mappings: canonicalMappings,
            rgsBalances: balances
        )

        TaxonomyShared.renderMappingSuggestions(
            unmatchedCodes: unmatched,
            mappings: canonicalMappings
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
