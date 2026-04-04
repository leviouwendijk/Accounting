import Foundation

public enum FinancialAveragesBuilder {
    private static let daysPerWeek = Decimal(7)
    private static let daysPerMonth = Decimal(string: "30.4375")!
    private static let daysPerQuarter = Decimal(string: "91.3125")!
    private static let daysPerHalf = Decimal(string: "182.625")!
    private static let daysPerYear = Decimal(string: "365.25")!

    public static func build(
        from inputs: FinancialRatioInputs,
        selection: FinancialPeriodUnitSelection,
        range: PeriodWindow,
        calendar: Calendar = periodCalendar()
    ) -> FinancialAverages? {
        guard selection.canCompareRealRange else {
            return nil
        }

        guard let spanDays = selection.spanDays
            ?? range.inclusiveDayCount(calendar: calendar),
            spanDays > 0
        else {
            return nil
        }

        var metrics: [FinancialAverageMetric] = []

        if let netIncome = inputs.netIncome,
           let metric = buildMetric(
                key: "netIncome",
                label: "Nettowinst",
                amount: netIncome,
                selection: selection,
                spanDays: spanDays
           ) {
            metrics.append(metric)
        }

        guard !metrics.isEmpty else {
            return nil
        }

        return .init(
            metrics: metrics
        )
    }

    private static func buildMetric(
        key: String,
        label: String,
        amount: Decimal,
        selection: FinancialPeriodUnitSelection,
        spanDays: Int
    ) -> FinancialAverageMetric? {
        let rows: [FinancialAverageRow] = selection.includedUnits.compactMap { unit -> FinancialAverageRow? in
            guard let divisor = divisor(
                for: unit,
                currentUnit: selection.currentUnit,
                spanDays: spanDays
            ), divisor != 0 else {
                return nil
            }

            return FinancialAverageRow(
                unit: unit,
                value: amount / divisor
            )
        }

        guard !rows.isEmpty else {
            return nil
        }

        return .init(
            key: key,
            label: label,
            rows: rows
        )
    }

    private static func divisor(
        for unit: FinancialPeriodUnit,
        currentUnit: FinancialPeriodUnit?,
        spanDays: Int
    ) -> Decimal? {
        if let exact = exactDivisor(
            for: unit,
            currentUnit: currentUnit,
            spanDays: spanDays
        ) {
            return exact
        }

        let span = Decimal(spanDays)

        switch unit {
        case .day:
            return span

        case .week:
            return span / daysPerWeek

        case .month:
            return span / daysPerMonth

        case .quarter:
            return span / daysPerQuarter

        case .half:
            return span / daysPerHalf

        case .year:
            return span / daysPerYear
        }
    }

    private static func exactDivisor(
        for unit: FinancialPeriodUnit,
        currentUnit: FinancialPeriodUnit?,
        spanDays: Int
    ) -> Decimal? {
        switch (currentUnit, unit) {
        case (.year, .half):
            return 2

        case (.year, .quarter):
            return 4

        case (.year, .month):
            return 12

        case (.half, .quarter):
            return 2

        case (.half, .month):
            return 6

        case (.quarter, .month):
            return 3

        case (.week, .day):
            return Decimal(spanDays)

        default:
            return nil
        }
    }
}
