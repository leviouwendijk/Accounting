import Accounting
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

        let accountLookup = TaxonomyProjection.makeAccountLookup(
            identifiers: accountCodes,
            codes: accountCodes
        )

        let loadedMapping = try TaxonomyLoader.loadGenericMapping(
            zipFileURL: zipFileURL,
            taxonomy: bootstrap
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

        print("selected generic mapping entrypoint:")
        print("  \(loadedMapping.selectedEntrypointPath)")
        print("")

        print("resolved mapping XML entries:")
        if loadedMapping.mappingEntryPaths.isEmpty {
            print("  none")
        } else {
            for path in loadedMapping.mappingEntryPaths {
                print("  \(path)")
            }
        }
        print("")

        for path in loadedMapping.mappingEntryPaths {
            if let diagnostics = loadedMapping.diagnostics[path] {
                print("mapping diagnostics for: \(path)")
                TaxonomyShared.renderMappingResolutionDiagnostics(
                    diagnostics
                )
                print("")
            }
        }

        let canonicalMappings = TaxonomyProjection.canonicalizeMappings(
            loadedMapping.resolvedMappings,
            lookup: accountLookup
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

            balances = try TaxonomyTester.projectBalances(
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

        TaxonomyShared.renderResolvedMappings(
            loadedMapping.resolvedMappings,
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
