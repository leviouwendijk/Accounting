import Foundation

public enum PeriodAssembler {
    public static func assemble(
        shape: PeriodShape,
        anchor: Date,
        result: EntryCompileDriver.Result,
        cut: AssembleCut = .init(target: .L3, includeCodes: [], includeIntermediates: true, omitZerosBeyondLevel1: true),
        omslag: OmslagMode = .apply,
        entity: BusinessEntity = .vof,
        tz: TimeZone = .current,
        calendar: Calendar = {
            var c = Calendar(identifier: .iso8601); c.firstWeekday = 2; return c
        }()
    ) throws -> PeriodAssembleResult {

        // 1) Chart + windows
        let chart = try buildChart(from: result)
        let wins  = resolveWindows(shape: shape, anchor: anchor, tz: tz, calendar: calendar)

        // 2) Current period
        let currentBundle = try buildCurrentBundle(
            chart: chart, wins: wins, result: result, cut: cut, omslag: omslag, entity: entity
        )
        let current = PeriodAssembleResultPeriod(range: wins.window, bundle: currentBundle)

        // 3) Previous (optional)
        let previous = try buildPreviousBundle(
            chart: chart, wins: wins, result: result, cut: cut, omslag: omslag, entity: entity
        ).map { PeriodAssembleResultPeriod(range: $0.range, bundle: $0.bundle) }

        return .init(current: current, previous: previous)
    }
}
