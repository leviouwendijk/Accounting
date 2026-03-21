import Foundation

extension TaxonomyProberRunner {
    public func runGenericMappingInspection(
        zipFileURL: URL,
        bootstrap: TaxonomyProbeBootstrap
    ) throws {
        guard let chartFile = config.chartFile else {
            throw TaxonomyProbeError.missingChartFile
        }

        let chart = try loadCompiledChart(
            from: chartFile
        )

        let accountCodes = chart.nodes.map(\.codes.code).filter { !$0.isEmpty }

        let entries = try listZIPEntries(
            zipFileURL: zipFileURL
        )

        let rankedCandidates = rankedZIPPaths(
            entries,
            keywords: config.probeKeywords,
            source: config.source
        )

        print("generic mapping candidates:")
        if rankedCandidates.isEmpty {
            print("  none")
            return
        }

        for entry in rankedCandidates.prefix(40) {
            let score = zipPathMatchScore(
                entry,
                keywords: config.probeKeywords,
                source: config.source
            )
            print("  [\(score)] \(entry)")
        }
        print("")

        let selectedEntry = rankedCandidates.first(where: {
            let lowercased = $0.lowercased()
            return lowercased.hasSuffix(".xml")
                || lowercased.hasSuffix(".xsd")
        })

        guard let selectedEntry else {
            throw TaxonomyProbeError.parseFailed(
                "no generic mapping candidate XML found in zip"
            )
        }

        print("selected generic mapping entry:")
        print("  \(selectedEntry)")
        print("")

        let xml = try readZIPEntryText(
            zipFileURL: zipFileURL,
            entryPath: selectedEntry
        )

        let linkbase = try TaxonomyGenericLinkbaseParser.parse(
            xml
        )

        let resolution = TaxonomyParser.resolveMappingsDetailed(
            from: linkbase
        )

        let canonicalMappings = canonicalizeMappings(
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

            balances = projectBalances(
                projectRoot: projectRoot
            )
        }

        let factsByKey = compileMappedFacts(
            mappings: canonicalMappings,
            rgsBalances: balances
        )

        let factsByConcept = groupMappedFactsByConceptKeepingDimensions(
            factsByKey
        )

        let flattenedFacts = projectMappedFactsToConceptFacts(
            factsByKey
        )

        renderMappingResolutionDiagnostics(
            resolution.diagnostics
        )
        print("")

        renderResolvedMappings(
            resolution.resolvedMappings,
            limit: 200
        )
        print("")

        renderCanonicalMappings(
            mappings: canonicalMappings,
            limit: 200
        )
        print("")

        renderComputedMappedFacts(
            factsByKey,
            limit: 200
        )
        print("")

        renderDemoBalanceCoverage(
            mappings: canonicalMappings,
            rgsBalances: balances
        )
        print("")

        renderUsedProjectCoverage(
            mappings: canonicalMappings,
            balances: balances
        )
        print("")

        let unmatched = unmatchedRGSCodes(
            mappings: canonicalMappings,
            rgsBalances: balances
        )

        renderMappingSuggestions(
            unmatchedCodes: unmatched,
            mappings: canonicalMappings
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
