import Foundation

public struct MetaAuditReport: Sendable {
    public let shape: PeriodShape
    public let anchor: Date
    public let overview: AssetsOverview
    public let filingReconciliation: AssetFilingReconciliationReport
    public let acquired: AcquiredAssetsReport
    public let period: NativePeriodCompileOutput
    public let depreciation: DepreciationAuditReport

    public init(
        shape: PeriodShape,
        anchor: Date,
        overview: AssetsOverview,
        filingReconciliation: AssetFilingReconciliationReport,
        acquired: AcquiredAssetsReport,
        period: NativePeriodCompileOutput,
        depreciation: DepreciationAuditReport
    ) {
        self.shape = shape
        self.anchor = anchor
        self.overview = overview
        self.filingReconciliation = filingReconciliation
        self.acquired = acquired
        self.period = period
        self.depreciation = depreciation
    }
}

public enum MetaAuditRunner {
    public static func run(
        result: EntryCompileDriver.Result,
        shape: PeriodShape,
        anchor: Date,
        tz: TimeZone = .current,
        calendar: Calendar = {
            var c = Calendar(identifier: .iso8601)
            c.firstWeekday = 2
            return c
        }(),
        cut: AssembleCut = .init(
            target: .L3,
            includeCodes: [],
            includeIntermediates: true,
            omitZerosBeyondLevel1: true
        ),
        omslag: OmslagMode = .apply,
        entity: BusinessEntity = .vof,
        reconciliationTolerance: Decimal = 0,
        depreciationOptions: DepreciationAuditRunner.Options = .init(
            granularity: .monthly,
            tolerance: 0,
            tolerateAggregateIntraQuarter: true
        )
    ) throws -> MetaAuditReport {
        let windows = PeriodSlicer.resolve(
            shape: shape,
            anchor: anchor,
            tz: tz,
            calendar: calendar
        )

        let overview = try AssetViews.AssetsOverviewBuilder.build(
            result: result,
            period: windows.window,
            calendar: calendar
        )

        let acquired = try AssetViews.AcquiredAssetsBuilder.build(
            result: result,
            period: windows.window,
            anchor: anchor,
            calendar: calendar
        )

        let period = try NativeOutputBuilder.buildPeriodOutput(
            result: result,
            shape: shape,
            anchor: anchor,
            cut: cut,
            omslag: omslag,
            entity: entity,
            tz: tz,
            calendar: calendar
        )

        let filingReconciliation = AssetViews.AssetFilingReconciliationBuilder.build(
            overview: overview,
            chart: period.chart,
            bundle: period.assembled.current.bundle,
            tolerance: reconciliationTolerance
        )

        var resolvedDepreciationOptions = depreciationOptions
        resolvedDepreciationOptions.calendar = calendar

        let depreciation = try DepreciationAuditRunner.run(
            entities: result.entities,
            accounts: result.accounts,
            resolvedEntries: result.resolved,
            through: windows.window.to ?? DepreciationAuditHorizon.endOfMonth(
                using: result.resolved,
                calendar: calendar
            ),
            options: resolvedDepreciationOptions
        )

        return .init(
            shape: shape,
            anchor: anchor,
            overview: overview,
            filingReconciliation: filingReconciliation,
            acquired: acquired,
            period: period,
            depreciation: depreciation
        )
    }

    public static func run(
        projectRoot: URL,
        shape: PeriodShape,
        anchor: Date,
        setting: CompileDriveSetting = .init(
            entities: true,
            accounts: true,
            transactions: true,
            entries: true,
            assertion: true
        ),
        verbose: Bool = false,
        tz: TimeZone = .current,
        calendar: Calendar = {
            var c = Calendar(identifier: .iso8601)
            c.firstWeekday = 2
            return c
        }(),
        cut: AssembleCut = .init(
            target: .L3,
            includeCodes: [],
            includeIntermediates: true,
            omitZerosBeyondLevel1: true
        ),
        omslag: OmslagMode = .apply,
        entity: BusinessEntity = .vof,
        reconciliationTolerance: Decimal = 0,
        depreciationOptions: DepreciationAuditRunner.Options = .init(
            granularity: .monthly,
            tolerance: 0,
            tolerateAggregateIntraQuarter: true
        )
    ) async throws -> MetaAuditReport {
        let result = try await EntryCompileDriver.compile(
            projectRoot: projectRoot,
            setting: setting,
            verbose: verbose
        )

        return try run(
            result: result,
            shape: shape,
            anchor: anchor,
            tz: tz,
            calendar: calendar,
            cut: cut,
            omslag: omslag,
            entity: entity,
            reconciliationTolerance: reconciliationTolerance,
            depreciationOptions: depreciationOptions
        )
    }
}
