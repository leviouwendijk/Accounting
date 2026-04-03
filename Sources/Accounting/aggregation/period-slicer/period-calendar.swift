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

// /// ISO-8601-ish calendar: Monday is first day, week 1 has ≥4 days.
// public func isoWeekCalendar(_ base: Calendar = .init(identifier: .gregorian)) -> Calendar {
//     var cal = base
//     cal.firstWeekday = 2                 // Monday
//     cal.minimumDaysInFirstWeek = 4
//     return cal
// }
