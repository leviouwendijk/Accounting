import Foundation
import plate

public enum LegacyPlanError: Error, LocalizedError {
    case missingDate(id: Int)
    case invalidDate(id: Int, value: String)
    case emptyFilename(id: Int)

    public var errorDescription: String? {
        switch self {
        case .missingDate(let id):
            return "Legacy entry \(id) has no date."
        case .invalidDate(let id, let v):
            return "Legacy entry \(id) has invalid date string: \(v)"
        case .emptyFilename(let id):
            return "Legacy entry \(id) produced an empty filename."
        }
    }
}

public struct IdentifiableByYQM: Hashable, Sendable {
    public let id: Int
    public let yqm: YQM
    
    public init(
        id: Int,
        yqm: YQM
    ) {
        self.id = id
        self.yqm = yqm
    }
}

public extension LegacyJournalEntry {
    func getYQM(tz: TimeZone = .current) throws -> YQM {
        guard let s = date?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty else {
            throw LegacyPlanError.missingDate(id: id)
        }
        let date: Date
        if let parsed = try? s.date() {
            date = parsed
        } else {
            throw LegacyPlanError.invalidDate(id: id, value: s)
        }
        return try yqm(for: date, tz: tz)
    }

    func plannedRelativePath(
        filename: String,
        padMonth: Bool = false,
        tz: TimeZone = .current
    ) throws -> String {
        guard !filename.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw LegacyPlanError.emptyFilename(id: id)
        }
        let yqm = try getYQM(tz: tz)
        let mDir = padMonth ? String(format: "%02d", yqm.month) : String(yqm.month)
        return "\(yqm.year)/\(yqm.quarter)/\(mDir)/\(filename).ec"
    }

    func identifiableYQM(tz: TimeZone = .current) throws -> IdentifiableByYQM {
        .init(id: id, yqm: try getYQM(tz: tz))
    }
}

public struct LegacyYQMSummary: Sendable, Codable {
    public let counts: [Int: [Int: [Int: Int]]] // year → quarter → month → count
}

public extension Array where Element == LegacyJournalEntry {
    func plannedRelativePathsAndSummary(
        filenameProvider: (LegacyJournalEntry) -> String,
        padMonth: Bool = false,
        tz: TimeZone = .current
    ) throws -> (paths: [String], summary: LegacyYQMSummary, formattedSummary: String) {
        var paths: [String] = []
        var counts: [Int: [Int: [Int: Int]]] = [:] // y→q→m→n

        paths.reserveCapacity(self.count)

        for e in self {
            let name = filenameProvider(e)
            let rel = try e.plannedRelativePath(filename: name, padMonth: padMonth, tz: tz)
            paths.append(rel)

            let yqm = try e.getYQM(tz: tz)
            var qMap = counts[yqm.year] ?? [:]
            var mMap = qMap[yqm.quarter] ?? [:]
            mMap[yqm.month, default: 0] += 1
            qMap[yqm.quarter] = mMap
            counts[yqm.year] = qMap
        }

        var lines: [String] = []
        let ys = counts.keys.sorted()
        for y in ys {
            lines.append("\(y):")
            let qs = counts[y]!.keys.sorted()
            for q in qs {
                lines.append("  Q\(q):")
                let ms = counts[y]![q]!.keys.sorted()
                for m in ms {
                    let n = counts[y]![q]![m]!
                    lines.append("    month \(m): \(n) entr\(n == 1 ? "y" : "ies")")
                }
            }
        }
        return (paths, .init(counts: counts), lines.joined(separator: "\n"))
    }
}

public extension Array where Element == LegacyJournalEntry {
    /// Index: id → YQM
    func yqmIndex(tz: TimeZone = .current) throws -> [Int: YQM] {
        var out: [Int: YQM] = [:]
        out.reserveCapacity(count)
        for e in self { out[e.id] = try e.getYQM(tz: tz) }
        return out
    }

    /// Group by (YQM, Type) → entries
    func groupedByYQMAndType(tz: TimeZone = .current) throws -> [YQM: [LegacyJournalEntryType: [LegacyJournalEntry]]] {
        var buckets: [YQM: [LegacyJournalEntryType: [LegacyJournalEntry]]] = [:]
        for e in self {
            let b = try e.getYQM(tz: tz)
            var byType = buckets[b] ?? [:]
            byType[e.type, default: []].append(e)
            buckets[b] = byType
        }
        return buckets
    }
}

public struct PlannedMonthlyTypeFile: Sendable {
    public let yqm: YQM
    public let type: LegacyJournalEntryType
    public let relativePath: String
    public let ids: [Int]
    
    public init(
        yqm: YQM,
        type: LegacyJournalEntryType,
        relativePath: String,
        ids: [Int]
    ) {
        self.yqm = yqm
        self.type = type
        self.relativePath = relativePath
        self.ids = ids
    }

    public var count: Int { ids.count }
}

public extension Array where Element == LegacyJournalEntry {
    /// Build plan: one file per (YQM, Type) with relative path and contained IDs.
    func planMonthlyTypeFiles(
        padMonth: Bool = false,
        tz: TimeZone = .current
    ) throws -> [PlannedMonthlyTypeFile] {
        let grouped = try groupedByYQMAndType(tz: tz)
        var out: [PlannedMonthlyTypeFile] = []
        out.reserveCapacity(grouped.count * 2)

        for (bucket, byType) in grouped {
            let mDir = padMonth ? String(format: "%02d", bucket.month) : String(bucket.month)
            for (t, entries) in byType {
                let rel = "\(bucket.year)/\(bucket.quarter)/\(mDir)/\(t.convertForEC()).ec"
                let ids = entries.map(\.id).sorted()
                out.append(.init(yqm: bucket, type: t, relativePath: rel, ids: ids))
            }
        }

        // stable order: by Y, Q, M, then type name
        out.sort {
            ($0.yqm.year, $0.yqm.quarter, $0.yqm.month, $0.type.convertForEC())
            <
            ($1.yqm.year, $1.yqm.quarter, $1.yqm.month, $1.type.convertForEC())
        }
        return out
    }

    /// Human summary like your “mary:” example (counts per Y/Q/month; all types combined).
    func monthlyCountSummary(tz: TimeZone = .current) throws -> String {
        var counts: [Int: [Int: [Int: Int]]] = [:] // y→q→m→n
        for e in self {
            let b = try e.getYQM(tz: tz)
            var qMap = counts[b.year] ?? [:]
            var mMap = qMap[b.quarter] ?? [:]
            mMap[b.month, default: 0] += 1
            qMap[b.quarter] = mMap
            counts[b.year] = qMap
        }
        var lines: [String] = []
        for y in counts.keys.sorted() {
            lines.append("\(y):")
            for q in counts[y]!.keys.sorted() {
                lines.append("  Q\(q):")
                for m in counts[y]![q]!.keys.sorted() {
                    let n = counts[y]![q]![m]!
                    lines.append("    month \(m): \(n) entr\(n == 1 ? "y" : "ies")")
                }
            }
        }
        return lines.joined(separator: "\n")
    }
}
