import Accounting
import Foundation
import Primitives

extension EntryCompilerDefaults {
    enum vat {
        static func anchor(
            for request: VATPeriodRequest,
            timeZone: TimeZone
        ) -> Date {
            guard request.kind == .quarter,
                  request.from == nil,
                  request.to == nil,
                  request.anchor == nil
            else {
                return Date()
            }

            let quarter = YearQuarter.lastCompleted(
                timeZone: timeZone,
                calendar: Calendar(identifier: .gregorian)
            )

            return quarter.startDate(
                timeZone: timeZone,
                calendar: Calendar(identifier: .gregorian)
            )
        }
    }
}

extension EntryCompilerLabels {
    static func vat(
        kind: PeriodKind,
        shape: PeriodShape,
        anchor: Date,
        window: PeriodWindow,
        calendar: Calendar
    ) -> String {
        switch kind {
        case .year where !shape.rangeToDate:
            return String(
                calendar.component(
                    .year,
                    from: anchor
                )
            )

        case .half where !shape.rangeToDate:
            let year = calendar.component(
                .year,
                from: anchor
            )

            let month = calendar.component(
                .month,
                from: anchor
            )

            let half = month <= 6 ? 1 : 2

            return "\(year)H\(half)"

        case .quarter where !shape.rangeToDate:
            return YearQuarter(
                containing: anchor,
                calendar: calendar
            )
            .label

        case .month where !shape.rangeToDate:
            let formatter = DateFormatter()
            formatter.calendar = calendar
            formatter.timeZone = calendar.timeZone
            formatter.dateFormat = "yyyy-MM"

            return formatter.string(
                from: anchor
            )

        default:
            return window.string()
        }
    }
}

extension EntryCompilerSlugs {
    static func vat(
        kind: PeriodKind,
        shape: PeriodShape,
        anchor: Date,
        window: PeriodWindow,
        timeZone: TimeZone,
        calendar: Calendar
    ) -> String {
        switch kind {
        case .year where !shape.rangeToDate:
            return String(
                calendar.component(
                    .year,
                    from: anchor
                )
            )

        case .half where !shape.rangeToDate:
            let year = calendar.component(
                .year,
                from: anchor
            )

            let month = calendar.component(
                .month,
                from: anchor
            )

            let half = month <= 6 ? 1 : 2

            return "\(year)-H\(half)"

        case .quarter where !shape.rangeToDate:
            return YearQuarter(
                containing: anchor,
                calendar: calendar
            )
            .slug

        case .month where !shape.rangeToDate:
            let formatter = DateFormatter()
            formatter.calendar = calendar
            formatter.timeZone = timeZone
            formatter.dateFormat = "yyyy-MM"

            return formatter.string(
                from: anchor
            )

        default:
            return window.filenameSlug(
                timeZone: timeZone
            )
        }
    }
}
