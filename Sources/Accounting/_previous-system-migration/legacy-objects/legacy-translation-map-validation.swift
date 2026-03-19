import Foundation

public struct LegacyOverrideValidationReport: Sendable, CustomStringConvertible {
    public struct Pair: Hashable, Sendable { public let entryId: Int; public let legacyId: Int }
    public let duplicatePairs: Set<Pair>                 // exact duplicates appearing in multiple overrides
    public let multiOverridesPerEntry: [Int: [LegacyMap]]// same entry id targeted by 2+ overrides (any legacyId)
    public var hasProblems: Bool {
        !duplicatePairs.isEmpty || !multiOverridesPerEntry.isEmpty
    }

    public var description: String {
        var lines: [String] = []
        if !duplicatePairs.isEmpty {
            lines.append("• Duplicate override pairs (entryId × legacyPrimaryId) found:")
            for p in duplicatePairs.sorted(by: { ($0.entryId, $0.legacyId) < ($1.entryId, $1.legacyId) }) {
                lines.append("    - (\(p.entryId), \(p.legacyId))")
            }
        }
        if !multiOverridesPerEntry.isEmpty {
            lines.append("• Entries overridden multiple times:")
            for (eid, maps) in multiOverridesPerEntry.sorted(by: { $0.key < $1.key }) {
                let ids = maps.map(\.legacyId).sorted()
                let names = maps.map { "\($0.legacyId):\($0.legacyName)" }.joined(separator: ", ")
                lines.append("    - entry \(eid): [\(ids.map(String.init).joined(separator: ", "))] (\(names))")
            }
        }
        return lines.isEmpty ? "No problems found." : lines.joined(separator: "\n")
    }
}

public enum LegacyOverrideValidationError: Error, LocalizedError {
    case duplicates(LegacyOverrideValidationReport)
    public var errorDescription: String? {
        switch self {
        case .duplicates(let r): return "Legacy override validation failed:\n\(r.description)"
        }
    }
}

public extension Array where Element == LegacyMapOverrideExceptions {
    func validateUniqueOverrides() throws -> LegacyOverrideValidationReport {
        var seenPairs = Set<LegacyOverrideValidationReport.Pair>()
        var dupPairs  = Set<LegacyOverrideValidationReport.Pair>()
        var byEntry   = [Int: [LegacyMap]]()

        for o in self {
            let map = o.legacyMapOverride
            for eid in o.legacyEntryIds {
                let pair = LegacyOverrideValidationReport.Pair(entryId: eid, legacyId: map.legacyId)
                if !seenPairs.insert(pair).inserted { dupPairs.insert(pair) }
                byEntry[eid, default: []].append(map)
            }
        }

        // Keep only entries that have 2+ overrides
        let multi = byEntry.filter { $0.value.count > 1 }
        let report = LegacyOverrideValidationReport(duplicatePairs: dupPairs, multiOverridesPerEntry: multi)
        if report.hasProblems { throw LegacyOverrideValidationError.duplicates(report) }
        return report
    }
}
