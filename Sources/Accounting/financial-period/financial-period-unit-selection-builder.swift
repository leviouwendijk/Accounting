import Foundation

public enum FinancialPeriodUnitSelectionBuilder {
    public static func build(
        shape: PeriodShape,
        range: PeriodWindow,
        calendar: Calendar = periodCalendar()
    ) -> FinancialPeriodUnitSelection {
        let currentUnit = currentFinancialUnit(
            for: shape.kind
        )

        guard range.isFinite else {
            return .init(
                basis: .unresolvedOpenRange,
                currentUnit: currentUnit,
                spanDays: nil,
                fittingUnits: [],
                includedUnits: [],
                excludedUnits: FinancialPeriodUnit.displayOrderDescending
            )
        }

        let fittingUnits = fittingFinancialUnits(
            in: range,
            calendar: calendar
        )

        let includedUnits = fittingUnits.filter {
            $0 != currentUnit
        }

        let excludedUnits = FinancialPeriodUnit.displayOrderDescending.filter {
            !includedUnits.contains($0)
        }

        return .init(
            basis: .resolvedFiniteRange,
            currentUnit: currentUnit,
            spanDays: range.inclusiveDayCount(
                calendar: calendar
            ),
            fittingUnits: fittingUnits,
            includedUnits: includedUnits,
            excludedUnits: excludedUnits
        )
    }

    @inline(__always)
    private static func currentFinancialUnit(
        for kind: PeriodKind
    ) -> FinancialPeriodUnit? {
        switch kind {
        case .year:
            return .year

        case .half:
            return .half

        case .quarter:
            return .quarter

        case .month:
            return .month

        case .week:
            return .week

        case .custom, .lifetime:
            return nil
        }
    }

    private static func fittingFinancialUnits(
        in range: PeriodWindow,
        calendar: Calendar
    ) -> [FinancialPeriodUnit] {
        guard let from = range.from, let to = range.to else {
            return []
        }

        let start = calendar.startOfDay(for: from)
        let end = endOfDay(
            to,
            calendar: calendar
        )

        return FinancialPeriodUnit.displayOrderDescending.filter { unit in
            unitFits(
                unit,
                start: start,
                end: end,
                calendar: calendar
            )
        }
    }

    @inline(__always)
    private static func unitFits(
        _ unit: FinancialPeriodUnit,
        start: Date,
        end: Date,
        calendar: Calendar
    ) -> Bool {
        guard let requiredEnd = endOfOneUnit(
            unit,
            from: start,
            calendar: calendar
        ) else {
            return false
        }

        return end >= requiredEnd
    }

    private static func endOfOneUnit(
        _ unit: FinancialPeriodUnit,
        from start: Date,
        calendar: Calendar
    ) -> Date? {
        switch unit {
        case .day:
            return endOfDay(
                start,
                calendar: calendar
            )

        case .week:
            guard let next = calendar.date(
                byAdding: .day,
                value: 7,
                to: start
            ),
            let last = calendar.date(
                byAdding: .day,
                value: -1,
                to: next
            ) else {
                return nil
            }

            return endOfDay(
                last,
                calendar: calendar
            )

        case .month:
            guard let next = calendar.date(
                byAdding: .month,
                value: 1,
                to: start
            ),
            let last = calendar.date(
                byAdding: .day,
                value: -1,
                to: next
            ) else {
                return nil
            }

            return endOfDay(
                last,
                calendar: calendar
            )

        case .quarter:
            guard let next = calendar.date(
                byAdding: .month,
                value: 3,
                to: start
            ),
            let last = calendar.date(
                byAdding: .day,
                value: -1,
                to: next
            ) else {
                return nil
            }

            return endOfDay(
                last,
                calendar: calendar
            )

        case .half:
            guard let next = calendar.date(
                byAdding: .month,
                value: 6,
                to: start
            ),
            let last = calendar.date(
                byAdding: .day,
                value: -1,
                to: next
            ) else {
                return nil
            }

            return endOfDay(
                last,
                calendar: calendar
            )

        case .year:
            guard let next = calendar.date(
                byAdding: .year,
                value: 1,
                to: start
            ),
            let last = calendar.date(
                byAdding: .day,
                value: -1,
                to: next
            ) else {
                return nil
            }

            return endOfDay(
                last,
                calendar: calendar
            )
        }
    }

    @inline(__always)
    private static func endOfDay(
        _ date: Date,
        calendar: Calendar
    ) -> Date {
        let start = calendar.startOfDay(for: date)
        let next = calendar.date(
            byAdding: .day,
            value: 1,
            to: start
        )!

        return calendar.date(
            byAdding: .second,
            value: -1,
            to: next
        )!
    }
}
