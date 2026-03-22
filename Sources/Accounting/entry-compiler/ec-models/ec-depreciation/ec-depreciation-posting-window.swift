import Foundation

public enum DepreciationPostingWindow {
    @inline(__always)
    public static func monthStart(for date: Date, calendar: Calendar) -> Date {
        calendar.date(
            from: calendar.dateComponents([.year, .month], from: date)
        )!
    }

    /// Canonical generated posting date for an audit item.
    /// We post on the final covered day of the audit window.
    @inline(__always)
    public static func postingDate(
        for item: DepreciationAuditItem,
        calendar: Calendar
    ) -> Date {
        calendar.date(byAdding: .day, value: -1, to: item.periodEnd) ?? item.periodEnd
    }

    /// Canonical month bucket for an audit item.
    @inline(__always)
    public static func postingMonthStart(
        for item: DepreciationAuditItem,
        calendar: Calendar
    ) -> Date {
        monthStart(for: postingDate(for: item, calendar: calendar), calendar: calendar)
    }

    @inline(__always)
    public static func belongsToMonth(
        _ item: DepreciationAuditItem,
        monthStart: Date,
        calendar: Calendar
    ) -> Bool {
        postingMonthStart(for: item, calendar: calendar) == monthStart
    }
}
