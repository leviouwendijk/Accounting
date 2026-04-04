import Foundation

public enum PeriodAssembler {
    public static func assemble(
        shape: PeriodShape,
        anchor: Date,
        result: EntryCompileDriver.Result,
        cut: AssembleCut = .init(
            target: .L3,
            includeCodes: [],
            includeIntermediates: true,
            omitZerosBeyondLevel1: true
        ),
        omslag: OmslagMode = .apply,
        entity: BusinessEntity = .vof,
        calendar: Calendar = periodCalendar()
    ) throws -> PeriodAssembleResult {
        let chart = try buildChart(from: result)
        let wins = resolveWindows(
            shape: shape,
            anchor: anchor,
            calendar: calendar
        )

        let currentBundle = try buildCurrentBundle(
            chart: chart,
            wins: wins,
            result: result,
            cut: cut,
            omslag: omslag,
            entity: entity,
            shape: shape,
            calendar: calendar
        )

        let current = PeriodAssembleResultPeriod(
            range: wins.window,
            bundle: currentBundle
        )

        let previous = try buildPreviousBundle(
            chart: chart,
            wins: wins,
            result: result,
            cut: cut,
            omslag: omslag,
            entity: entity,
            shape: shape,
            calendar: calendar
        ).map {
            PeriodAssembleResultPeriod(
                range: $0.range,
                bundle: $0.bundle
            )
        }

        return .init(
            current: current,
            previous: previous
        )
    }

    public static func assemble_concurrent(
        shape: PeriodShape,
        anchor: Date,
        result: EntryCompileDriver.Result,
        cut: AssembleCut = .init(
            target: .L3,
            includeCodes: [],
            includeIntermediates: true,
            omitZerosBeyondLevel1: true
        ),
        omslag: OmslagMode = .apply,
        entity: BusinessEntity = .vof,
        calendar: Calendar = periodCalendar()
    ) async throws -> PeriodAssembleResult {
        let chart = try buildChart(from: result)
        let wins = resolveWindows(
            shape: shape,
            anchor: anchor,
            calendar: calendar
        )

        async let currentBundleTask: StatementBundle = try await buildCurrentBundleConcurrent(
            chart: chart,
            wins: wins,
            result: result,
            cut: cut,
            omslag: omslag,
            entity: entity,
            shape: shape,
            calendar: calendar
        )

        async let previousTupleTask: (range: PeriodWindow, bundle: StatementBundle)? = try buildPreviousBundleConcurrent(
            chart: chart,
            wins: wins,
            result: result,
            cut: cut,
            omslag: omslag,
            entity: entity,
            shape: shape,
            calendar: calendar
        )

        let currentBundle = try await currentBundleTask
        let previousTuple = try await previousTupleTask

        let current = PeriodAssembleResultPeriod(
            range: wins.window,
            bundle: currentBundle
        )

        let previous = previousTuple.map {
            PeriodAssembleResultPeriod(
                range: $0.range,
                bundle: $0.bundle
            )
        }

        return .init(
            current: current,
            previous: previous
        )
    }
}
