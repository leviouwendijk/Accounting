import Foundation

public enum PeriodSlicer {
    public static func resolve(
        shape: PeriodShape,
        anchor: Date = Date(),
        customFrom: Date? = nil,
        customTo: Date? = nil,
        tz: TimeZone = .current,
        calendar base: Calendar = {
            var c = Calendar(identifier: .iso8601)
            c.firstWeekday = 2 // Monday
            return c
        }()
    ) -> PeriodWindows {
        var cal = base; cal.timeZone = tz

        func dayStart(_ d: Date) -> Date {
            let c = cal.dateComponents([.year,.month,.day], from: d)
            return cal.date(from: c)!
        }
        func dayEnd(_ d: Date) -> Date {
            var c = cal.dateComponents([.year,.month,.day], from: d)
            c.hour = 23; c.minute = 59; c.second = 59
            return cal.date(from: c)!
        }
        func startOfYear(_ d: Date) -> Date {
            cal.date(from: cal.dateComponents([.year], from: d))!
        }
        func endOfYear(_ d: Date) -> Date {
            let s = startOfYear(d)
            return dayEnd(cal.date(byAdding: .day, value: -1, to: cal.date(byAdding: .year, value: 1, to: s)!)!)
        }

        func startOfHalf(_ d: Date) -> Date {
            let comps = cal.dateComponents([.year, .month], from: d)
            let m = comps.month ?? 1
            let halfStartMonth = (m <= 6) ? 1 : 7
            return cal.date(from: DateComponents(year: comps.year, month: halfStartMonth, day: 1))!
        }
        func endOfHalf(fromStart s: Date) -> Date {
            let sixMonthsLater = cal.date(byAdding: .month, value: 6, to: s)!
            return dayEnd(cal.date(byAdding: .day, value: -1, to: sixMonthsLater)!)
        }

        func startOfQuarter(_ d: Date) -> Date {
            let comps = cal.dateComponents([.year,.month], from: d)
            let qstart = (((comps.month ?? 1) - 1)/3)*3 + 1
            return cal.date(from: DateComponents(year: comps.year, month: qstart, day: 1))!
        }
        func endOfQuarter(fromStart s: Date) -> Date {
            dayEnd(cal.date(byAdding: .day, value: -1, to: cal.date(byAdding: .month, value: 3, to: s)!)!)
        }
        func startOfMonth(_ d: Date) -> Date {
            cal.date(from: cal.dateComponents([.year,.month], from: d))!
        }
        func endOfMonth(fromStart s: Date) -> Date {
            dayEnd(cal.date(byAdding: .day, value: -1, to: cal.date(byAdding: .month, value: 1, to: s)!)!)
        }
        func startOfISOWeek(_ d: Date) -> Date {
            let wd = cal.component(.weekday, from: d)
            let delta = (wd == 1 ? -6 : (2 - wd)) // Sun=1 → go back 6; Mon=2 → 0
            return dayStart(cal.date(byAdding: .day, value: delta, to: d)!)
        }
        func endOfISOWeek(fromStart s: Date) -> Date {
            dayEnd(cal.date(byAdding: .day, value: 6, to: s)!)
        }
        func previousWindow(sameLengthAs cur: PeriodWindow) -> PeriodWindow? {
            guard let f = cur.from, let t = cur.to else { return nil }
            let len = (cal.dateComponents([.day], from: dayStart(f), to: dayStart(t)).day ?? 0) + 1
            let pTo = dayEnd(cal.date(byAdding: .day, value: -1, to: f)!)
            let pFrom = dayStart(cal.date(byAdding: .day, value: -(len-1), to: pTo)!)
            return .init(from: pFrom, to: pTo)
        }

        let a = anchor

        // compute the main window
        let window: PeriodWindow = {
            switch shape.kind {
            case .lifetime:
                return .init(from: nil, to: nil)

            case .custom:
                // toDate flag is ignored for custom
                let f = customFrom.map(dayStart)
                let t = customTo.map(dayEnd)
                return .init(from: f, to: t)

            case .year:
                let f = startOfYear(a)
                let t = shape.rangeToDate ? dayEnd(a) : endOfYear(a)
                return .init(from: f, to: t)

            case .half: // NEW
                let f = startOfHalf(a)
                let t = shape.rangeToDate ? dayEnd(a) : endOfHalf(fromStart: f)
                return .init(from: f, to: t)

            case .quarter:
                let f = startOfQuarter(a)
                let t = shape.rangeToDate ? dayEnd(a) : endOfQuarter(fromStart: f)
                return .init(from: f, to: t)

            case .month:
                let f = startOfMonth(a)
                let t = shape.rangeToDate ? dayEnd(a) : endOfMonth(fromStart: f)
                return .init(from: f, to: t)

            case .week:
                let f = startOfISOWeek(a)
                let t = shape.rangeToDate ? dayEnd(a) : endOfISOWeek(fromStart: f)
                return .init(from: f, to: t)

            }
        }()

        let historical = PeriodWindow(
            from: nil,
            to: window.from.map { dayEnd(cal.date(byAdding: .day, value: -1, to: $0)!) }
        )
        let ytd = PeriodWindow(from: nil, to: window.to)
        let prev = previousWindow(sameLengthAs: window)
        return .init(historical: historical, window: window, ytd: ytd, previous: prev)
    }
}

@inline(__always)
public func absDate(_ d: DateSpecification) -> Date? {
    if case let .absolute(x) = d { return x }
    return nil
}

@inline(__always)
public func filterEntries(_ src: [ResolvedEntry], within w: PeriodWindow) -> [ResolvedEntry] {
    src.filter { re in
        guard let d = absDate(re.date) else { return false }
        return within(d, window: w)
    }
}

@inline(__always)
public func within(_ date: Date, window w: PeriodWindow) -> Bool {
    if let f = w.from, date < f { return false }
    if let t = w.to,   date > t { return false }
    return true
}
