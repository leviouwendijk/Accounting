import Foundation

public enum NativeOutputBuilder {
    public static func buildCompileOutput(
        result: EntryCompileDriver.Result,
        cut: AssembleCut,
        omslag: OmslagMode,
        entity: BusinessEntity = .vof,
        autoClose: Bool = true
    ) throws -> NativeCompileOutput {
        let chart = try PeriodAssembler.buildChart(from: result)
        let tbRows = trialBalance(result.resolved)

        let bundle = try RGSAssembler.assemble(
            chart: chart,
            trialRows: tbRows,
            cut: cut,
            omslag: omslag,
            for: entity,
            autoClose: autoClose
        )

        return .init(
            result: result,
            chart: chart,
            bundle: bundle
        )
    }

    public static func buildPeriodOutput(
        result: EntryCompileDriver.Result,
        shape: PeriodShape,
        anchor: Date,
        cut: AssembleCut,
        omslag: OmslagMode,
        entity: BusinessEntity = .vof,
        calendar: Calendar = periodCalendar()
    ) throws -> NativePeriodCompileOutput {
        let chart = try PeriodAssembler.buildChart(from: result)

        let assembled = try PeriodAssembler.assemble(
            shape: shape,
            anchor: anchor,
            result: result,
            cut: cut,
            omslag: omslag,
            entity: entity,
            calendar: calendar
        )

        return .init(
            result: result,
            chart: chart,
            shape: shape,
            assembled: assembled
        )
    }
}

// public enum NativeOutputBuilder {
//     public static func buildCompileOutput(
//         result: EntryCompileDriver.Result,
//         cut: AssembleCut,
//         omslag: OmslagMode,
//         entity: BusinessEntity = .vof,
//         autoClose: Bool = true
//     ) throws -> NativeCompileOutput {
//         let chart = try PeriodAssembler.buildChart(from: result)
//         let tbRows = trialBalance(result.resolved)

//         let bundle = try RGSAssembler.assemble(
//             chart: chart,
//             trialRows: tbRows,
//             cut: cut,
//             omslag: omslag,
//             for: entity,
//             autoClose: autoClose
//         )

//         return .init(
//             result: result,
//             chart: chart,
//             bundle: bundle
//         )
//     }

//     public static func buildPeriodOutput(
//         result: EntryCompileDriver.Result,
//         shape: PeriodShape,
//         anchor: Date,
//         cut: AssembleCut,
//         omslag: OmslagMode,
//         entity: BusinessEntity = .vof,
//         tz: TimeZone = .current,
//         calendar: Calendar = {
//             var c = Calendar(identifier: .iso8601)
//             c.firstWeekday = 2
//             return c
//         }()
//     ) throws -> NativePeriodCompileOutput {
//         let chart = try PeriodAssembler.buildChart(from: result)

//         let assembled = try PeriodAssembler.assemble(
//             shape: shape,
//             anchor: anchor,
//             result: result,
//             cut: cut,
//             omslag: omslag,
//             entity: entity,
//             tz: tz,
//             calendar: calendar
//         )

//         return .init(
//             result: result,
//             chart: chart,
//             shape: shape,
//             assembled: assembled
//         )
//     }
// }
