import Foundation

extension TaxonomyProber {
    public static func csvPathPriorityScore(
        _ path: String,
        source: TaxonomySourceData
    ) -> Int {
        let value = path.lowercased()
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
    ) -> String? {
        let normalizedTarget = targetEntrypointBasename.lowercased()

        let sorted = entries
            .filter { $0.lowercased().hasSuffix(".csv") }
            .sorted {
                let leftScore = csvPathPriorityScore($0, source: source)
                let rightScore = csvPathPriorityScore($1, source: source)

                if leftScore == rightScore {
                    return $0 < $1
                }

                return leftScore > rightScore
            }

        if let exactBasenameMatch = sorted.first(where: {
            let basename = URL(fileURLWithPath: $0)
                .deletingPathExtension()
                .lastPathComponent
                .lowercased()
            return basename == normalizedTarget
        }) {
            return exactBasenameMatch
        }

        if let containsBasenameMatch = sorted.first(where: {
            $0.lowercased().contains(normalizedTarget)
        }) {
            return containsBasenameMatch
        }

        let basenameTokens = Set(
            normalizedTarget
                .split(whereSeparator: { !$0.isLetter && !$0.isNumber })
                .map(String.init)
                .filter { !$0.isEmpty }
        )

        let tokenScored = sorted.map { entry in
            let entryLowercased = entry.lowercased()
            let tokenHits = basenameTokens.reduce(into: 0) { partial, token in
                if entryLowercased.contains(token) {
                    partial += 1
                }
            }

            return (
                entry: entry,
                tokenHits: tokenHits,
                priority: csvPathPriorityScore(entry, source: source)
            )
        }
        .sorted { lhs, rhs in
            if lhs.tokenHits == rhs.tokenHits {
                if lhs.priority == rhs.priority {
                    return lhs.entry < rhs.entry
                }

                return lhs.priority > rhs.priority
            }

            return lhs.tokenHits > rhs.tokenHits
        }

        guard let best = tokenScored.first, best.tokenHits > 0 else {
            return nil
        }

        return best.entry
    }

    public static func zipPathMatchScore(
        _ path: String,
        keywords: [String],
        source: TaxonomySourceData
    ) -> Int {
        let lowercasedPath = path.lowercased()
        var score = 0

        for keyword in keywords {
            if lowercasedPath.contains(keyword.lowercased()) {
                score += 10
            }
        }

        for pattern in source.probePatterns {
            if lowercasedPath.contains(pattern.lowercased()) {
                score += 12
            }
        }

        if lowercasedPath.hasSuffix(".xml") {
            score += 5
        }

        if lowercasedPath.contains("/presentation/") {
            score += 8
        }

        if lowercasedPath.contains("/dictionary/") {
            score += 4
        }

        if lowercasedPath.contains("/definition/") {
            score += 4
        }

        return score
    }

    public static func rankedZIPPaths(
        _ entries: [String],
        keywords: [String],
        source: TaxonomySourceData
    ) -> [String] {
        entries
            .map { entry in
                (
                    entry: entry,
                    score: zipPathMatchScore(
                        entry,
                        keywords: keywords,
                        source: source
                    )
                )
            }
            .filter { $0.score > 0 }
            .sorted { lhs, rhs in
                if lhs.score == rhs.score {
                    return lhs.entry < rhs.entry
                }

                return lhs.score > rhs.score
            }
            .map(\.entry)
    }

    public static func candidateTextEntries(
        _ entries: [String]
    ) -> [String] {
        entries.filter { entry in
            let ext = fileExtensionLowercased(for: entry)

            switch ext {
            case "xml", "xsd", "xbrl", "csv", "txt", "json":
                return true
            default:
                return false
            }
        }
    }

    public static func rankedTextEntries(
        _ entries: [String],
        keywords: [String],
        source: TaxonomySourceData
    ) -> [String] {
        let candidates = candidateTextEntries(entries)

        return rankedZIPPaths(
            candidates,
            keywords: keywords,
            source: source
        )
    }

    public static func fileExtensionLowercased(
        for path: String
    ) -> String {
        URL(fileURLWithPath: path)
            .pathExtension
            .lowercased()
    }
}

public func csvPathPriorityScore(
    _ path: String,
    source: TaxonomySourceData
) -> Int {
    TaxonomyProber.csvPathPriorityScore(
        path,
        source: source
    )
}

public func resolveRGSMappingEntrypointPath(
    entries: [String],
    targetEntrypointBasename: String,
    source: TaxonomySourceData
) -> String? {
    TaxonomyProber.resolveRGSMappingEntrypointPath(
        entries: entries,
        targetEntrypointBasename: targetEntrypointBasename,
        source: source
    )
}

public func zipPathMatchScore(
    _ path: String,
    keywords: [String],
    source: TaxonomySourceData
) -> Int {
    TaxonomyProber.zipPathMatchScore(
        path,
        keywords: keywords,
        source: source
    )
}

public func rankedZIPPaths(
    _ entries: [String],
    keywords: [String],
    source: TaxonomySourceData
) -> [String] {
    TaxonomyProber.rankedZIPPaths(
        entries,
        keywords: keywords,
        source: source
    )
}

public func candidateTextEntries(
    _ entries: [String]
) -> [String] {
    TaxonomyProber.candidateTextEntries(entries)
}

public func rankedTextEntries(
    _ entries: [String],
    keywords: [String],
    source: TaxonomySourceData
) -> [String] {
    TaxonomyProber.rankedTextEntries(
        entries,
        keywords: keywords,
        source: source
    )
}

public func fileExtensionLowercased(
    for path: String
) -> String {
    TaxonomyProber.fileExtensionLowercased(for: path)
}
