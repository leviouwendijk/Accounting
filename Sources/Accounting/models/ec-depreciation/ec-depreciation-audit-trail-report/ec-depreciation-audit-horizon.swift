import Foundation

public enum DepreciationAuditHorizonError: Error, Equatable, Sendable {
    case noAbsoluteEntryDates
    case unresolvedEntryDate
}

public enum DepreciationAuditHorizon {
    /// End-of-month for the latest absolute posting date.
    /// Empty or unresolved input cannot silently acquire the current month.
    public static func endOfMonth(
        using entries: [ResolvedEntry],
        calendar: Calendar = .init(identifier: .gregorian)
    ) throws -> Date {
        guard entries.allSatisfy({
            if case .absolute = $0.date { return true }
            return false
        }) else {
            throw DepreciationAuditHorizonError.unresolvedEntryDate
        }

        guard let latest = entries.compactMap({ re -> Date? in
            if case let .absolute(date) = re.date { return date }
            return nil
        }).max() else {
            throw DepreciationAuditHorizonError.noAbsoluteEntryDates
        }

        return endOfMonth(containing: latest, calendar: calendar)
    }

    // new for going past entries end?
    public static func endOfMonth(
        containing date: Date,
        calendar: Calendar = .init(identifier: .gregorian)
    ) -> Date {
        let startOfMonth = calendar.date(
            from: calendar.dateComponents([.year, .month], from: date)
        )!
        let nextMonth = calendar.date(
            byAdding: DateComponents(month: 1),
            to: startOfMonth
        )!
        return calendar.date(byAdding: .day, value: -1, to: nextMonth)!
    }
}
