import Foundation

extension TaxonomyProbe {
    public static func resolveZIPEntryPath(
        _ href: String,
        relativeTo entryPath: String
    ) throws -> String {
        if href.contains("://") {
            throw Error.invalidURL("Absolute ZIP href not supported: \(href)")
        }

        let baseURL = URL(fileURLWithPath: "/" + entryPath)
            .deletingLastPathComponent()

        let resolvedURL = URL(fileURLWithPath: href, relativeTo: baseURL)
            .standardizedFileURL

        let path = resolvedURL.path

        guard path.hasPrefix("/") else {
            throw Error.parseFailed("Could not resolve ZIP entry path: \(href) relative to \(entryPath)")
        }

        return String(path.dropFirst())
    }
}

extension TaxonomyProbe {
    public static func listZIPEntries(zipFileURL: URL) throws -> [String] {
        let unzip = try unzipPath()
        let output = try runCommand(unzip, ["-Z1", zipFileURL.path])
        return output
            .split(separator: "\n", omittingEmptySubsequences: true)
            .map(String.init)
    }

    public static func readZIPEntryText(zipFileURL: URL, entryPath: String) throws -> String {
        let unzip = try unzipPath()
        return try runCommand(unzip, ["-p", zipFileURL.path, entryPath])
    }

    public static func csvPathPriorityScore(
        _ entry: String,
        source: TaxonomySourceData
    ) -> Int {
        let value = entry.lowercased()
        var score = 0

        for (index, keyword) in source.csvPriorityKeywords.map({ $0.lowercased() }).enumerated() {
            if value.contains(keyword) {
                score += max(1, source.csvPriorityKeywords.count - index) * 20
            }
        }

        if value.contains("/mapping/") {
            score += 25
        }

        if value.hasSuffix(".csv") {
            score += 10
        }

        for bonus in source.zipPathBonusRules {
            if value.contains(bonus.needle.lowercased()) {
                score += bonus.score
            }
        }

        return score
    }

    public static func resolveRGSMappingEntrypointPath(
        entries: [String],
        targetEntrypointBasename: String,
        source: TaxonomySourceData
    ) throws -> String {
        for candidate in source.mappingEntrypointCandidates(for: targetEntrypointBasename) {
            if let match = entries.first(where: { $0.hasSuffix(candidate) }) {
                return match
            }
        }

        let tried = source.mappingEntrypointCandidates(for: targetEntrypointBasename)
            .joined(separator: ", ")

        throw Error.parseFailed(
            "Could not find RGS mapping entrypoint for \(targetEntrypointBasename). tried suffixes: \(tried)"
        )
    }

    public static func extractMatchingMappingCSV(
        zipFileURL: URL,
        entrypointBasename: String,
        source: TaxonomySourceData
    ) throws -> (entryPath: String, text: String) {
        print("listing zip entries...")
        let entries = try listZIPEntries(zipFileURL: zipFileURL)
        print("zip entries: \(entries.count)")

        let csvEntries = entries.filter { $0.lowercased().hasSuffix(".csv") }
        print("csv entries: \(csvEntries.count)")

        let prioritized = csvEntries.sorted { lhs, rhs in
            let lhsScore = csvPathPriorityScore(lhs, source: source)
            let rhsScore = csvPathPriorityScore(rhs, source: source)

            if lhsScore == rhsScore {
                return lhs < rhs
            }

            return lhsScore > rhsScore
        }

        for (index, entry) in prioritized.enumerated() {
            print("reading csv candidate \(index + 1)/\(prioritized.count): \(entry)")
            let text = try readZIPEntryText(zipFileURL: zipFileURL, entryPath: entry)

            if text.contains("SBR_ENTRYPOINT;") && text.contains(entrypointBasename) {
                print("matched mapping csv: \(entry)")
                return (entry, text)
            }
        }

        throw Error.mappingCSVNotFound(entrypointBasename)
    }

    public static func zipPathMatchScore(
        _ entry: String,
        keywords: [String],
        source: TaxonomySourceData? = nil
    ) -> Int {
        let value = entry.lowercased()
        let basename = URL(fileURLWithPath: entry).lastPathComponent.lowercased()

        var score = 0

        for keyword in keywords.map({ $0.lowercased() }) {
            if basename.contains(keyword) {
                score += 20
            }

            if value.contains(keyword) {
                score += 10
            }
        }

        if value.contains("/mapping/") {
            score += 25
        }
        if value.contains("/entrypoints/") {
            score += 20
        }
        if value.contains("/presentation/") {
            score += 15
        }
        if value.contains("/definition/") {
            score += 15
        }
        if value.contains("/table/") {
            score += 15
        }
        if value.contains("/dictionary/") {
            score += 15
        }

        if value.hasSuffix(".xml") || value.hasSuffix(".xsd") {
            score += 10
        }

        if let source {
            for bonus in source.zipPathBonusRules {
                if value.contains(bonus.needle.lowercased()) {
                    score += bonus.score
                }
            }
        }

        return score
    }

    public static func rankedZIPPaths(
        _ entries: [String],
        keywords: [String],
        source: TaxonomySourceData? = nil
    ) -> [(entry: String, score: Int)] {
        entries
            .map { ($0, zipPathMatchScore($0, keywords: keywords, source: source)) }
            .filter { $0.1 > 0 }
            .sorted { lhs, rhs in
                if lhs.1 == rhs.1 {
                    return lhs.0 < rhs.0
                }

                return lhs.1 > rhs.1
            }
    }

    public static func printMatchingZIPPaths(
        _ entries: [String],
        keywords: [String],
        source: TaxonomySourceData? = nil,
        limit: Int = 100
    ) {
        let matches = rankedZIPPaths(
            entries,
            keywords: keywords,
            source: source
        )

        print("path matches for keywords \(keywords): \(matches.count)")
        for match in matches.prefix(limit) {
            print("  [\(match.score)] \(match.entry)")
        }
        print("")
    }

    public static func rankedTextEntries(
        _ entries: [String],
        keywords: [String],
        source: TaxonomySourceData? = nil
    ) -> [String] {
        rankedZIPPaths(
            candidateTextEntries(entries),
            keywords: keywords,
            source: source
        )
        .map(\.entry)
    }

    public static func candidateTextEntries(_ entries: [String]) -> [String] {
        let allowed: Set<String> = [
            "xml",
            "xsd",
            "xsl",
            "txt",
            "csv",
            "json",
            "htm",
            "html"
        ]

        return entries.filter { allowed.contains(fileExtensionLowercased(for: $0)) }
    }

    public static func findTextHitsInZIP(
        zipFileURL: URL,
        entries: [String],
        keywords: [String],
        patterns: [String],
        source: TaxonomySourceData? = nil,
        maxFilesToScan: Int = 300,
        maxHits: Int = 50
    ) throws {
        let textEntries = candidateTextEntries(entries)
        let rankedEntries = rankedTextEntries(
            entries,
            keywords: keywords,
            source: source
        )
        let loweredPatterns = patterns.map { $0.lowercased() }

        print("text-like entries: \(textEntries.count)")
        print("scanning first \(min(maxFilesToScan, rankedEntries.count)) ranked text-like files for patterns...")

        var hits = 0

        for entry in rankedEntries.prefix(maxFilesToScan) {
            let text = try readZIPEntryText(zipFileURL: zipFileURL, entryPath: entry)
            let lowered = text.lowercased()

            let matchedPatterns = loweredPatterns.filter { lowered.contains($0) }
            if matchedPatterns.isEmpty {
                continue
            }

            print("hit: \(entry)")
            print("  matched: \(matchedPatterns.joined(separator: ", "))")
            hits += 1

            if hits >= maxHits {
                print("")
                print("hit limit reached: \(maxHits)")
                return
            }
        }

        print("")
        print("total hits: \(hits)")
    }

    public static func fileExtensionLowercased(for path: String) -> String {
        let ext = URL(fileURLWithPath: path).pathExtension.lowercased()
        return ext.isEmpty ? "(none)" : ext
    }

    public static func summarizeZIPEntries(_ entries: [String]) {
        var counts: [String: Int] = [:]

        for entry in entries {
            let ext = fileExtensionLowercased(for: entry)
            counts[ext, default: 0] += 1
        }

        print("extensions:")
        for key in counts.keys.sorted() {
            print("  \(key): \(counts[key] ?? 0)")
        }
        print("")
    }
}
