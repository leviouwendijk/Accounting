import Accounting
import Foundation
import Position

public enum EntryPlaceholderDetection: String, Hashable, Codable, Sendable {
    case explicit
    case alias_suffix
}

public struct EntryPlaceholderFinding: Hashable, Codable, Sendable {
    public let entryIndex: Int
    public let lineIndex: Int
    public let entryID: Int?
    public let entryLocation: Position?
    public let location: Position?
    public let entityAlias: String
    public let kind: EntityPlaceholderKind?
    public let detection: EntryPlaceholderDetection
}

public struct EntryPlaceholderReport: Hashable, Codable, Sendable {
    public let entryCount: Int
    public let affectedEntryCount: Int
    public let findings: [EntryPlaceholderFinding]

    public var totalOccurrences: Int { findings.count }
}

public enum EntryPlaceholderInspector {
    public static func inspect(entries: [Entry]) -> EntryPlaceholderReport {
        var findings: [EntryPlaceholderFinding] = []
        var affected = 0
        for (entryIndex, entry) in entries.enumerated() {
            var found = false
            for (lineIndex, line) in entry.lines.enumerated() {
                let explicit = line.entity.placeholder
                let alias = line.entity.alias.name
                guard explicit != nil || alias.hasSuffix("_placeholder") else { continue }
                found = true
                findings.append(.init(
                    entryIndex: entryIndex,
                    lineIndex: lineIndex,
                    entryID: entry.id,
                    entryLocation: entry.location,
                    location: line.location,
                    entityAlias: alias,
                    kind: explicit?.kind,
                    detection: explicit == nil ? .alias_suffix : .explicit
                ))
            }
            if found { affected += 1 }
        }
        return .init(entryCount: entries.count, affectedEntryCount: affected, findings: findings)
    }

    public static func inspect(
        project: EntryCompilerProject,
        settings: EntryCompilerSettings,
        trace: Bool = true
    ) throws -> EntryPlaceholderReport {
        let entries = try EntryCompilerEntriesLoader.load(
            from: project, settings: settings,
            allowCollisions: true, trace: trace, verbose: false
        )
        return inspect(entries: entries)
    }

    public static func inspect(
        project: EntryCompilerProject,
        settings: EntryCompilerSettings,
        trace: Bool = true
    ) async throws -> EntryPlaceholderReport {
        let entries = try await EntryCompilerEntriesLoader.load(
            from: project, settings: settings,
            allowCollisions: true, trace: trace, verbose: false
        )
        return inspect(entries: entries)
    }
}
