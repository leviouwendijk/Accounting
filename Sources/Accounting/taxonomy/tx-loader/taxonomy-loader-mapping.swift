import Foundation

extension TaxonomyLoader {
    public static func loadCSVMapping(
        zipFileURL: URL,
        taxonomy: LoadedTaxonomy
    ) throws -> LoadedTaxonomyCSVMapping {
        let extracted = try extractMatchingMappingCSV(
            zipFileURL: zipFileURL,
            entrypointBasename: taxonomy.entrypointBasename,
            source: taxonomy.source
        )

        let mappingFile = try TaxonomyCSVParser.parseMappingCSV(
            extracted.csv
        )

        return LoadedTaxonomyCSVMapping(
            entryPath: extracted.entryPath,
            mappingFile: mappingFile
        )
    }
}

extension TaxonomyLoader {
    public static func loadGenericMapping(
        zipFileURL: URL,
        taxonomy: LoadedTaxonomy
    ) throws -> LoadedTaxonomyGenericMapping {
        let entries = try listZIPEntries(
            zipFileURL: zipFileURL
        )

        let rankedCandidates = rankedZIPPaths(
            entries,
            keywords: taxonomy.source.probeKeywords,
            source: taxonomy.source
        )

        // guard let selectedEntrypointPath = resolveRGSMappingEntrypointPath(
        guard let selectedEntrypointPath = resolveMappingEntrypointPath(
            entries: entries,
            targetEntrypointBasename: taxonomy.entrypointBasename,
            source: taxonomy.source
        ) else {
            throw TaxonomyProbeError.parseFailed(
                // "could not resolve RGS mapping entrypoint for \(taxonomy.entrypointBasename)"
                "could not resolve generic mapping entrypoint for \(taxonomy.entrypointBasename)"
            )
        }

        let entrypointXML = try readZIPEntryText(
            zipFileURL: zipFileURL,
            entryPath: selectedEntrypointPath
        )

        let refs = try TaxonomyEntrypointParser.parse(
            entrypointXML,
            source: taxonomy.source
        )

        guard !refs.mappings.isEmpty else {
            throw TaxonomyProbeError.parseFailed(
                "resolved mapping entrypoint has no mapping refs: \(selectedEntrypointPath)"
            )
        }

        let mappingEntryPaths = refs.mappings.map { ref in
            resolveZIPEntryPath(
                ref.href,
                relativeTo: selectedEntrypointPath
            )
        }

        var allResolvedMappings: [TaxonomyResolvedMapping] = []
        var diagnosticsByEntryPath: [String: TaxonomyMappingResolutionDiagnostics] = [:]

        for mappingEntryPath in mappingEntryPaths {
            let mappingXML = try readZIPEntryText(
                zipFileURL: zipFileURL,
                entryPath: mappingEntryPath
            )

            let linkbase = try TaxonomyGenericLinkbaseParser.parse(
                mappingXML
            )

            let resolution = TaxonomyParser.resolveMappingsDetailed(
                from: linkbase
            )

            allResolvedMappings.append(contentsOf: resolution.resolvedMappings)
            diagnosticsByEntryPath[mappingEntryPath] = resolution.diagnostics
        }

        return LoadedTaxonomyGenericMapping(
            rankedCandidates: rankedCandidates,
            selectedEntrypointPath: selectedEntrypointPath,
            mappingEntryPaths: mappingEntryPaths,
            resolvedMappings: allResolvedMappings,
            diagnostics: diagnosticsByEntryPath
        )
    }
}
