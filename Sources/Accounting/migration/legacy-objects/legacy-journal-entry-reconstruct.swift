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
