import Accounting
import Foundation

extension TaxonomyProber {
    public static func printMatchingZIPPaths(
        _ entries: [String],
        keywords: [String],
        source: TaxonomySourceData,
        limit: Int = 80
    ) {
        let ranked = TaxonomyLoader.rankedZIPPaths(
            entries,
            keywords: keywords,
            source: source
        )

        print("ranked matching zip paths:")
        if ranked.isEmpty {
            print("  none")
            return
        }

        for entry in ranked.prefix(limit) {
            let score = TaxonomyLoader.zipPathMatchScore(
                entry,
                keywords: keywords,
                source: source
            )
            print("  [\(score)] \(entry)")
        }

        if ranked.count > limit {
            print("  ... +\(ranked.count - limit) more")
        }
    }

    public static func findTextHitsInZIP(
        zipFileURL: URL,
        entries: [String],
        keywords: [String],
        patterns: [String],
        source: TaxonomySourceData,
        maxFilesToScan: Int,
        maxHits: Int
    ) -> [(entry: String, line: String)] {
        let ranked = TaxonomyLoader.rankedTextEntries(
            entries,
            keywords: keywords,
            source: source
        )

        var hits: [(entry: String, line: String)] = []

        for entry in ranked.prefix(maxFilesToScan) {
            guard hits.count < maxHits else {
                break
            }

            guard let text = try? TaxonomyLoader.readZIPEntryText(
                zipFileURL: zipFileURL,
                entryPath: entry
            ) else {
                continue
            }

            let lowercasedKeywords = keywords.map { $0.lowercased() }
            let lowercasedPatterns = patterns.map { $0.lowercased() }

            for rawLine in text.components(separatedBy: .newlines) {
                guard hits.count < maxHits else {
                    break
                }

                let line = TaxonomyShared.trim(rawLine)
                guard !line.isEmpty else {
                    continue
                }

                let haystack = line.lowercased()

                let keywordHit = lowercasedKeywords.contains { haystack.contains($0) }
                let patternHit = lowercasedPatterns.contains { haystack.contains($0) }

                guard keywordHit || patternHit else {
                    continue
                }

                hits.append((entry: entry, line: line))
            }
        }

        return hits
    }

    public static func summarizeZIPEntries(
        _ entries: [String]
    ) {
        let countsByExtension = Dictionary(
            grouping: entries,
            by: { TaxonomyLoader.fileExtensionLowercased(for: $0) }
        ).mapValues(\.count)

        let ordered = countsByExtension.keys.sorted { lhs, rhs in
            let left = countsByExtension[lhs] ?? 0
            let right = countsByExtension[rhs] ?? 0

            if left == right {
                return lhs < rhs
            }

            return left > right
        }

        print("zip entry summary:")
        print("  total entries: \(entries.count)")

        for ext in ordered {
            let rendered = ext.isEmpty ? "<no extension>" : ext
            print("  \(rendered): \(countsByExtension[ext] ?? 0)")
        }
    }
}
