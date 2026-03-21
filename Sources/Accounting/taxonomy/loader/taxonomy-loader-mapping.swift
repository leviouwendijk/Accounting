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
        source: TaxonomySourceData,
        probeKeywords: [String]
    ) throws -> LoadedTaxonomyGenericMapping {
        let entries = try listZIPEntries(
            zipFileURL: zipFileURL
        )

        let rankedCandidates = rankedZIPPaths(
            entries,
            keywords: probeKeywords,
            source: source
        )

        guard let selectedEntryPath = rankedCandidates.first(where: {
            let lowercased = $0.lowercased()
            return lowercased.hasSuffix(".xml")
                || lowercased.hasSuffix(".xsd")
        }) else {
            throw TaxonomyProbeError.parseFailed(
                "no generic mapping candidate XML found in zip"
            )
        }

        let xml = try readZIPEntryText(
            zipFileURL: zipFileURL,
            entryPath: selectedEntryPath
        )

        let linkbase = try TaxonomyGenericLinkbaseParser.parse(
            xml
        )

        return LoadedTaxonomyGenericMapping(
            rankedCandidates: rankedCandidates,
            selectedEntryPath: selectedEntryPath,
            linkbase: linkbase
        )
    }
}
