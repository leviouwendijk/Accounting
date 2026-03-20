import Foundation

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

    public static func extractMatchingMappingCSV(
        zipFileURL: URL,
        entrypointBasename: String
    ) throws -> (entryPath: String, text: String) {
        print("listing zip entries...")
        let entries = try listZIPEntries(zipFileURL: zipFileURL)
        print("zip entries: \(entries.count)")

        let csvEntries = entries.filter { $0.lowercased().hasSuffix(".csv") }
        print("csv entries: \(csvEntries.count)")

        let prioritized = csvEntries.sorted { lhs, rhs in
            let lhsScore = (lhs.lowercased().contains("ihz") ? 0 : 1) + (lhs.lowercased().contains("aangifte") ? 0 : 1)
            let rhsScore = (rhs.lowercased().contains("ihz") ? 0 : 1) + (rhs.lowercased().contains("aangifte") ? 0 : 1)

            if lhsScore == rhsScore {
                return lhs < rhs
            }

            return lhsScore < rhsScore
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

    public static func printMatchingZIPPaths(
        _ entries: [String],
        keywords: [String],
        limit: Int = 100
    ) {
        let loweredKeywords = keywords.map { $0.lowercased() }

        let matches = entries.filter { entry in
            let value = entry.lowercased()
            return loweredKeywords.contains { value.contains($0) }
        }

        print("path matches for keywords \(keywords): \(matches.count)")
        for entry in matches.prefix(limit) {
            print("  \(entry)")
        }
        print("")
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
        patterns: [String],
        maxFilesToScan: Int = 300,
        maxHits: Int = 50
    ) throws {
        let textEntries = candidateTextEntries(entries)
        let loweredPatterns = patterns.map { $0.lowercased() }

        print("text-like entries: \(textEntries.count)")
        print("scanning first \(min(maxFilesToScan, textEntries.count)) text-like files for patterns...")
        print("")

        var hits = 0

        for entry in textEntries.prefix(maxFilesToScan) {
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
}
