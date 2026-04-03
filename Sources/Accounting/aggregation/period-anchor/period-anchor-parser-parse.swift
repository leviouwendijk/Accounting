import Foundation

extension PeriodAnchorParser {
    public static func parse(
        _ raw: String,
        kind: PeriodKind,
        timeZone: TimeZone = .current,
        calendar base: Calendar = defaultCalendar()
    ) throws -> Date {
        var calendar = base
        calendar.timeZone = timeZone

        let trimmed = raw.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !trimmed.isEmpty else {
            throw PeriodAnchorParseError.invalidAnchor(
                raw: raw,
                kind: kind,
                expected: expectedFormats(for: kind)
            )
        }

        if let fullDate = try parseFullDateIfPresent(
            trimmed,
            label: "--anchor",
            timeZone: timeZone,
            calendar: calendar
        ) {
            return fullDate
        }

        switch kind {
        case .year:
            return try parseYearAnchor(
                trimmed,
                timeZone: timeZone,
                calendar: calendar
            )

        case .half:
            return try parseHalfAnchor(
                trimmed,
                timeZone: timeZone,
                calendar: calendar
            )

        case .quarter:
            return try parseQuarterAnchor(
                trimmed,
                timeZone: timeZone,
                calendar: calendar
            )

        case .month:
            return try parseMonthAnchor(
                trimmed,
                timeZone: timeZone,
                calendar: calendar
            )

        case .week:
            return try parseWeekAnchor(
                trimmed,
                timeZone: timeZone,
                calendar: calendar
            )

        case .custom, .lifetime:
            throw PeriodAnchorParseError.invalidAnchor(
                raw: raw,
                kind: kind,
                expected: "YYYY-MM-DD"
            )
        }
    }
}
