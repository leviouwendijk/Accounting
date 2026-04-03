import Foundation

extension PeriodAnchorParser {
    public static func parseFullDate(
        _ raw: String,
        label: String = "--date",
        timeZone: TimeZone = .current,
        calendar base: Calendar = defaultCalendar()
    ) throws -> Date {
        var calendar = base
        calendar.timeZone = timeZone

        guard let date = try parseFullDateIfPresent(
            raw.trimmingCharacters(in: .whitespacesAndNewlines),
            label: label,
            timeZone: timeZone,
            calendar: calendar
        ) else {
            throw PeriodAnchorParseError.invalidFullDate(
                raw: raw,
                label: label
            )
        }

        return date
    }

    internal static func parseYearAnchor(
        _ raw: String,
        timeZone: TimeZone,
        calendar: Calendar
    ) throws -> Date {
        guard raw.count == 4,
              let year = Int(raw) else {
            throw PeriodAnchorParseError.invalidAnchor(
                raw: raw,
                kind: .year,
                expected: expectedFormats(for: .year)
            )
        }

        return try makeDate(
            year: year,
            month: 1,
            day: 1,
            timeZone: timeZone,
            calendar: calendar,
            label: "--anchor"
        )
    }

    internal static func parseHalfAnchor(
        _ raw: String,
        timeZone: TimeZone,
        calendar: Calendar
    ) throws -> Date {
        let normalized = raw.uppercased()

        if normalized.count == 6,
           let year = Int(normalized.prefix(4)),
           normalized[normalized.index(normalized.startIndex, offsetBy: 4)] == "H",
           let half = Int(String(normalized.last!)),
           (1...2).contains(half) {
            let month = half == 1 ? 1 : 7

            return try makeDate(
                year: year,
                month: month,
                day: 1,
                timeZone: timeZone,
                calendar: calendar,
                label: "--anchor"
            )
        }

        let parts = raw.split(separator: "-", maxSplits: 1).map(String.init)
        if parts.count == 2,
           let year = Int(parts[0]),
           let month = Int(parts[1]),
           [1, 7].contains(month) {
            return try makeDate(
                year: year,
                month: month,
                day: 1,
                timeZone: timeZone,
                calendar: calendar,
                label: "--anchor"
            )
        }

        throw PeriodAnchorParseError.invalidAnchor(
            raw: raw,
            kind: .half,
            expected: expectedFormats(for: .half)
        )
    }

    internal static func parseQuarterAnchor(
        _ raw: String,
        timeZone: TimeZone,
        calendar: Calendar
    ) throws -> Date {
        let normalized = raw.uppercased()

        if normalized.count == 6,
           let year = Int(normalized.prefix(4)),
           normalized[normalized.index(normalized.startIndex, offsetBy: 4)] == "Q",
           let quarter = Int(String(normalized.last!)),
           (1...4).contains(quarter) {
            let month = ((quarter - 1) * 3) + 1

            return try makeDate(
                year: year,
                month: month,
                day: 1,
                timeZone: timeZone,
                calendar: calendar,
                label: "--anchor"
            )
        }

        let parts = raw.split(separator: "-", maxSplits: 1).map(String.init)
        if parts.count == 2,
           let year = Int(parts[0]),
           let month = Int(parts[1]),
           [1, 4, 7, 10].contains(month) {
            return try makeDate(
                year: year,
                month: month,
                day: 1,
                timeZone: timeZone,
                calendar: calendar,
                label: "--anchor"
            )
        }

        throw PeriodAnchorParseError.invalidAnchor(
            raw: raw,
            kind: .quarter,
            expected: expectedFormats(for: .quarter)
        )
    }

    internal static func parseMonthAnchor(
        _ raw: String,
        timeZone: TimeZone,
        calendar: Calendar
    ) throws -> Date {
        let parts = raw.split(separator: "-", maxSplits: 1).map(String.init)

        guard parts.count == 2,
              let year = Int(parts[0]),
              let month = Int(parts[1]),
              (1...12).contains(month) else {
            throw PeriodAnchorParseError.invalidAnchor(
                raw: raw,
                kind: .month,
                expected: expectedFormats(for: .month)
            )
        }

        return try makeDate(
            year: year,
            month: month,
            day: 1,
            timeZone: timeZone,
            calendar: calendar,
            label: "--anchor"
        )
    }

    internal static func parseWeekAnchor(
        _ raw: String,
        timeZone: TimeZone,
        calendar: Calendar
    ) throws -> Date {
        let normalized = raw.uppercased()
        let parts = normalized.split(separator: "-", maxSplits: 1).map(String.init)

        guard parts.count == 2,
              let year = Int(parts[0]),
              parts[1].hasPrefix("W"),
              let week = Int(parts[1].dropFirst()),
              (1...53).contains(week) else {
            throw PeriodAnchorParseError.invalidAnchor(
                raw: raw,
                kind: .week,
                expected: expectedFormats(for: .week)
            )
        }

        var weekCalendar = calendar
        weekCalendar.firstWeekday = 2
        weekCalendar.minimumDaysInFirstWeek = 4

        guard let date = weekCalendar.date(
            from: DateComponents(
                calendar: weekCalendar,
                timeZone: timeZone,
                weekday: 2,
                weekOfYear: week,
                yearForWeekOfYear: year
            )
        ) else {
            throw PeriodAnchorParseError.invalidAnchor(
                raw: raw,
                kind: .week,
                expected: expectedFormats(for: .week)
            )
        }

        return date
    }

    internal static func parseFullDateIfPresent(
        _ raw: String,
        label: String,
        timeZone: TimeZone,
        calendar: Calendar
    ) throws -> Date? {
        let parts = raw.split(separator: "-", omittingEmptySubsequences: false)
            .map(String.init)

        guard parts.count == 3 else {
            return nil
        }

        guard let year = Int(parts[0]),
              let month = Int(parts[1]),
              let day = Int(parts[2]) else {
            throw PeriodAnchorParseError.invalidFullDate(
                raw: raw,
                label: label
            )
        }

        return try makeDate(
            year: year,
            month: month,
            day: day,
            timeZone: timeZone,
            calendar: calendar,
            label: label
        )
    }

    internal static func makeDate(
        year: Int,
        month: Int,
        day: Int,
        timeZone: TimeZone,
        calendar: Calendar,
        label: String
    ) throws -> Date {
        guard let date = calendar.date(
            from: DateComponents(
                calendar: calendar,
                timeZone: timeZone,
                year: year,
                month: month,
                day: day
            )
        ) else {
            throw PeriodAnchorParseError.invalidFullDate(
                raw: "\(year)-\(month)-\(day)",
                label: label
            )
        }

        return date
    }

    internal static func expectedFormats(
        for kind: PeriodKind
    ) -> String {
        switch kind {
        case .year:
            return "YYYY or YYYY-MM-DD"

        case .half:
            return "YYYYH1, YYYYH2, YYYY-01, YYYY-07, or YYYY-MM-DD"

        case .quarter:
            return "YYYYQ1..YYYYQ4, YYYY-01, YYYY-04, YYYY-07, YYYY-10, or YYYY-MM-DD"

        case .month:
            return "YYYY-MM or YYYY-MM-DD"

        case .week:
            return "YYYY-Www or YYYY-MM-DD"

        case .custom, .lifetime:
            return "YYYY-MM-DD"
        }
    }

    public static func defaultCalendar(
        timeZone: TimeZone = .current
    ) -> Calendar {
        periodCalendar(
            timeZone: timeZone
        )
    }
}
