import Foundation
import Accounting
import plate

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
