import Foundation

public extension NativeOutputBuilder {
    static func buildWindowOutput(
        result: EntryCompileDriver.Result,
        windows: PeriodWindows,
        rangeToDate: Bool = false,
        cut: AssembleCut,
        omslag: OmslagMode,
        entity: BusinessEntity = .vof
    ) throws -> NativeCompileOutput {
        let chart = try PeriodAssembler.buildChart(from: result)

        let bundle = try PeriodAssembler.buildCurrentBundle(
            chart: chart,
            wins: windows,
            result: result,
            cut: cut,
            omslag: omslag,
            entity: entity,
            rangeToDate: rangeToDate
        )

        return .init(
            result: result,
            chart: chart,
            bundle: bundle
        )
    }
}
