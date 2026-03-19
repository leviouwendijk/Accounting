import Foundation
import plate

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
