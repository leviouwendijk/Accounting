import Foundation
import Accounting
import plate

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
