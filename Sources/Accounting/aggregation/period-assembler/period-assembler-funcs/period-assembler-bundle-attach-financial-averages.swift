import Foundation

public extension PeriodAssembler {
    @inline(__always)
    static func attachFinancialAverages(
        _ bundle: StatementBundle,
        shape: PeriodShape,
        range: PeriodWindow,
        calendar: Calendar
    ) -> StatementBundle {
        guard let analytics = bundle.analytics,
              let inputs = analytics.ratioInputs
        else {
            return bundle
        }

        let selection = FinancialPeriodUnitSelectionBuilder.build(
            shape: shape,
            range: range,
            calendar: calendar
        )

        let averages = FinancialAveragesBuilder.build(
            from: inputs,
            selection: selection,
            range: range,
            calendar: calendar
        )

        return bundle.withAnalytics(
            analytics.withAverages(averages)
        )
    }
}
