import Foundation

/// Canonical calendar for period slicing / period labeling / anchor parsing.
/// Monday-first, ISO week semantics, with an explicit timezone.
public func periodCalendar(
    timeZone: TimeZone = .current,
    base: Calendar = .init(identifier: .iso8601)
) -> Calendar {
    var calendar = base
    calendar.timeZone = timeZone
    calendar.firstWeekday = 2
    calendar.minimumDaysInFirstWeek = 4
    return calendar
}

/// Backwards-compatible alias if older call sites still reference this helper.
public func isoWeekCalendar(
    _ base: Calendar = .init(identifier: .iso8601),
    timeZone: TimeZone = .current
) -> Calendar {
    periodCalendar(
        timeZone: timeZone,
        base: base
    )
}

public extension Calendar {
    @inline(__always)
    func dayEnd(
        _ date: Date
    ) -> Date {
        let start = startOfDay(for: date)
        let next = self.date(
            byAdding: .day,
            value: 1,
            to: start
        )!

        return self.date(
            byAdding: .second,
            value: -1,
            to: next
        )!
    }

    @inline(__always)
    static func dayEnd(
        _ date: Date,
        calendar: Calendar
    ) -> Date {
        calendar.dayEnd(date)
    }
}

// /// ISO-8601-ish calendar: Monday is first day, week 1 has ≥4 days.
// public func isoWeekCalendar(_ base: Calendar = .init(identifier: .gregorian)) -> Calendar {
//     var cal = base
//     cal.firstWeekday = 2                 // Monday
//     cal.minimumDaysInFirstWeek = 4
//     return cal
// }

@available(
    *,
    message: "Used previously by PeriodAssembler. Use period-calendar.swift based APIs instead. Kept around for regression rollback."
)
public extension Calendar {
    static var iso8601: Calendar { 
        var c = Calendar(identifier: .iso8601)
        c.firstWeekday = 2; return c 
    }

    static func iso8601DayEnd(_ d: Date) -> Date {
        var c = Calendar.iso8601.dateComponents([.year,.month,.day], from: d)
        c.hour = 23
        c.minute = 59
        c.second = 59
        return Calendar.iso8601.date(from: c)!
    }
}
