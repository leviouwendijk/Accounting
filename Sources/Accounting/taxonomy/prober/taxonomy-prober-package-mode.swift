import Foundation

extension TaxonomyProberRunner {
    public func runPackageProbe(
        zipFileURL: URL
    ) throws {
        let entries = try listZIPEntries(
            zipFileURL: zipFileURL
        )

        summarizeZIPEntries(entries)
        print("")
        printMatchingZIPPaths(
            entries,
            keywords: config.probeKeywords,
            source: config.source
        )
        print("")

        let hits = findTextHitsInZIP(
            zipFileURL: zipFileURL,
            entries: entries,
            keywords: config.probeKeywords,
            patterns: config.probePatterns,
            source: config.source,
            maxFilesToScan: config.maxFilesToScan,
            maxHits: config.maxHits
        )

        print("text hits:")
        if hits.isEmpty {
            print("  none")
            return
        }

        for hit in hits {
            print("  \(hit.entry)")
            print("    \(hit.line)")
        }
    }
}
