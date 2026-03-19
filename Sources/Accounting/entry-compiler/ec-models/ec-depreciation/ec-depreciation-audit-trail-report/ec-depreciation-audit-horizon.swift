import Foundation

public enum DepreciationAuditHorizon {
    /// End-of-month for the latest absolute date found in the resolved entries.
    public static func endOfMonth(using entries: [ResolvedEntry], calendar: Calendar = .init(identifier: .gregorian)) -> Date {
        // Extract absolute dates; resolved pass should have made dates absolute
        let latest = entries.compactMap { re -> Date? in
            if case let .absolute(d) = re.date { return d }
            return nil
        }.max() ?? Date()

        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: latest))!
        let nextMonth    = calendar.date(byAdding: DateComponents(month: 1), to: startOfMonth)!
        return calendar.date(byAdding: .day, value: -1, to: nextMonth)!
    }
}
