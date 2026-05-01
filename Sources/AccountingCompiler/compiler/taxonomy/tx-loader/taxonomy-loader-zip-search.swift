import Accounting
import Foundation

extension TaxonomyLoader {
    public static func extractMatchingMappingCSV(
        zipFileURL: URL,
        entrypointBasename: String,
        source: TaxonomySourceData
    ) throws -> (
        entryPath: String,
        csv: String
    ) {
        let entries = try listZIPEntries(zipFileURL: zipFileURL)

        guard let entryPath = resolveRGSMappingEntrypointPath(
            entries: entries,
            targetEntrypointBasename: entrypointBasename,
            source: source
        ) else {
            throw TaxonomyProbeError.mappingCSVNotFound(entrypointBasename)
        }

        let csv = try readZIPEntryText(
            zipFileURL: zipFileURL,
            entryPath: entryPath
        )

        return (
            entryPath: entryPath,
            csv: csv
        )
    }
}
