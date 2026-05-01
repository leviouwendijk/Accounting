import Accounting
import Foundation

public extension NativeOutputBuilder {
    static func buildWindowOutput(
        result: EntryCompileDriver.Result,
        windows: PeriodWindows,
        shape: PeriodShape,
        cut: AssembleCut,
        omslag: OmslagMode,
        entity: BusinessEntity = .vof,
        calendar: Calendar = periodCalendar()
    ) throws -> NativeCompileOutput {
        let chart = try PeriodAssembler.buildChart(from: result)

        let bundle = try PeriodAssembler.buildCurrentBundle(
            chart: chart,
            wins: windows,
            result: result,
            cut: cut,
            omslag: omslag,
            entity: entity,
            shape: shape,
            calendar: calendar
        )

        return .init(
            result: result,
            chart: chart,
            bundle: bundle
        )
    }
}
