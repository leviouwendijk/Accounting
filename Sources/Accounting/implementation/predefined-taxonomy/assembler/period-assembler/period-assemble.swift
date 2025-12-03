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
            chart: chart, wins: wins, result: result, cut: cut, omslag: omslag, entity: entity,
            rangeToDate: shape.rangeToDate
        )
        let current = PeriodAssembleResultPeriod(range: wins.window, bundle: currentBundle)

        // 3) Previous (optional)
        let previous = try buildPreviousBundle(
            chart: chart, wins: wins, result: result, cut: cut, omslag: omslag, entity: entity,
            rangeToDate: shape.rangeToDate
        ).map { PeriodAssembleResultPeriod(range: $0.range, bundle: $0.bundle) }

        return .init(current: current, previous: previous)
    }

    /// Async variant: builds current + previous bundles in parallel once chart/windows are known.
    public static func assemble_concurrent(
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
    ) async throws -> PeriodAssembleResult {

        // 1) Chart + windows (cheap, do synchronously on caller's executor)
        let chart = try buildChart(from: result)
        let wins  = resolveWindows(shape: shape, anchor: anchor, tz: tz, calendar: calendar)

        // 2) Kick off current + previous work in parallel
        async let currentBundleTask: StatementBundle = try await buildCurrentBundleConcurrent(
            chart: chart,
            wins: wins,
            result: result,
            cut: cut,
            omslag: omslag,
            entity: entity,
            rangeToDate: shape.rangeToDate
        )

        async let previousTupleTask: (range: PeriodWindow, bundle: StatementBundle)? = try buildPreviousBundleConcurrent(
            chart: chart,
            wins: wins,
            result: result,
            cut: cut,
            omslag: omslag,
            entity: entity,
            rangeToDate: shape.rangeToDate
        )

        // 3) Join
        let currentBundle = try await currentBundleTask
        let previousTuple = try await previousTupleTask

        let current = PeriodAssembleResultPeriod(range: wins.window, bundle: currentBundle)
        let previous = previousTuple.map { PeriodAssembleResultPeriod(range: $0.range, bundle: $0.bundle) }

        return .init(current: current, previous: previous)
    }
}
