import Foundation
import Primitives

public enum PeriodKind: String, Codable, Sendable, StringParsableEnum {
    case year
    case half // half year
    case quarter
    case month
    case week            // ISO-8601 week (Mon–Sun)
    case custom
    case lifetime             // no filter
}

// additions:

/// ISO-8601-ish calendar: Monday is first day, week 1 has ≥4 days.
public func isoWeekCalendar(_ base: Calendar = .init(identifier: .gregorian)) -> Calendar {
    var cal = base
    cal.firstWeekday = 2                 // Monday
    cal.minimumDaysInFirstWeek = 4
    return cal
}

public func periodStart(for date: Date, kind: PeriodKind, calendar base: Calendar) -> Date {
    var cal = base
    if kind == .week {
        cal.firstWeekday = 2
        cal.minimumDaysInFirstWeek = 4
    }

    switch kind {
    case .year:
        let comps = cal.dateComponents([.year], from: date)
        return cal.date(from: comps)! // 1 Jan 00:00 of that year
    case .half:
        var comps = cal.dateComponents([.year, .month], from: date)
        comps.month = ( (comps.month ?? 1) <= 6 ) ? 1 : 7
        comps.day = 1
        return cal.date(from: comps)!
    case .quarter:
        var comps = cal.dateComponents([.year, .month], from: date)
        let m = comps.month ?? 1
        comps.month = ((m - 1) / 3) * 3 + 1
        comps.day = 1
        return cal.date(from: comps)!
    case .month:
        var comps = cal.dateComponents([.year, .month], from: date)
        comps.day = 1
        return cal.date(from: comps)!
    case .week:
        let d = cal.startOfDay(for: date)
        let wd = cal.component(.weekday, from: d)
        let delta = (wd >= cal.firstWeekday)
            ? (wd - cal.firstWeekday)
            : (7 - (cal.firstWeekday - wd))
        return cal.date(byAdding: .day, value: -delta, to: d)!
    case .custom:
        return date
    case .lifetime:
        return date
    }
}

public func nextPeriodStart(after start: Date, kind: PeriodKind, calendar base: Calendar) -> Date {
    var cal = base
    if kind == .week {
        cal.firstWeekday = 2
        cal.minimumDaysInFirstWeek = 4
    }
    switch kind {
    case .year:
        return cal.date(byAdding: .year, value: 1, to: start)!
    case .half:
        return cal.date(byAdding: .month, value: 6, to: start)!
    case .quarter:
        return cal.date(byAdding: .month, value: 3, to: start)!
    case .month:
        return cal.date(byAdding: .month, value: 1, to: start)!
    case .week:
        return cal.date(byAdding: .day, value: 7, to: start)!
    case .custom:
        // caller must decide; we’ll treat “custom” same as lifetime here
        return start
    case .lifetime:
        return start
    }
}

public func labelForPeriodStart(
    _ start: Date,
    kind: PeriodKind,
    calendar base: Calendar = .init(identifier: .gregorian)
) -> String {
    let cal = (kind == .week) ? isoWeekCalendar(base) : base

    switch kind {
    case .year:
        return String(cal.component(.year, from: start))

    case .half:
        let y = cal.component(.year,  from: start)
        let m = cal.component(.month, from: start)
        let h = (m <= 6) ? 1 : 2
        return "H\(h) \(y)"

    case .quarter:
        let y = cal.component(.year,  from: start)
        let m = cal.component(.month, from: start)
        let q = ((m - 1) / 3) + 1
        return "Q\(q) \(y)"

    case .month:
        let y = cal.component(.year,  from: start)
        let m = cal.component(.month, from: start)
        return String(format: "%04d-%02d", y, m)

    case .week:
        let y = cal.component(.yearForWeekOfYear, from: start)
        let w = cal.component(.weekOfYear,        from: start)
        return String(format: "W%02d %d", w, y)

    case .custom:
        return "custom"

    case .lifetime:
        return "lifetime"
    }
}
