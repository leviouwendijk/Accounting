import Foundation

public extension ResolvedPeriodRequest {
    func financialPeriodUnitSelection(
        calendar: Calendar = periodCalendar()
    ) -> FinancialPeriodUnitSelection {
        FinancialPeriodUnitSelectionBuilder.build(
            shape: effectiveShape,
            range: windows.window,
            calendar: calendar
        )
    }
}
