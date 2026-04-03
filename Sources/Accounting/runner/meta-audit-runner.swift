import Foundation

public enum MetaAuditRunner {
    public static func run(
        result: EntryCompileDriver.Result,
        settings: EntryCompilerSettings,
        shape: PeriodShape,
        anchor: Date,
        // tz: TimeZone = .current,
        // calendar: Calendar = {
        //     var c = Calendar(identifier: .iso8601)
        //     c.firstWeekday = 2
        //     return c
        // }(),

        calendar: Calendar = periodCalendar(),
        cut: AssembleCut = .init(
            target: .L3,
            includeCodes: [],
            includeIntermediates: true,
            omitZerosBeyondLevel1: true
        ),
        omslag: OmslagMode = .apply,
        entity: BusinessEntity = .vof,
        equityComparePrevious: Bool = false,
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
            // tz: tz,
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
            // tz: tz,
            calendar: calendar
        )

        let filingReconciliation = AssetViews.AssetFilingReconciliationBuilder.build(
            overview: overview,
            chart: period.chart,
            bundle: period.assembled.current.bundle,
            tolerance: reconciliationTolerance
        )

        let costBreakdown = try CostViews.CostBreakdownBuilder.build(
            period: period.assembled.current.range,
            chart: period.chart,
            bundle: period.assembled.current.bundle,
            omslag: omslag,
            tolerance: reconciliationTolerance
        )

        var kiaCalendar = Calendar(identifier: .gregorian)
        kiaCalendar.timeZone = settings.entry.defaultTimezone

        let taxYear = kiaCalendar.component(
            .year,
            from: anchor
        )

        let kia: MetaAuditKIASection = {
            guard let kiaConfig = KIAConfigs.netherlands(year: taxYear) else {
                let message = "No KIA config available for year \(taxYear). KIA section omitted."
                fputs("warning: \(message)\n", stderr)

                return .init(
                    taxYear: taxYear,
                    result: nil,
                    warning: message
                )
            }

            let result = KIAProjection.run(
                entities: result.entities,
                request: .init(
                    period: .init(taxYear: taxYear),
                    config: kiaConfig
                ),
                calendar: kiaCalendar
            )

            return .init(
                taxYear: taxYear,
                result: result,
                warning: nil
            )
        }()

        let equity = try buildEquitySection(
            result: result,
            settings: settings,
            kind: shape.kind,
            comparePrevious: equityComparePrevious,
            chart: period.chart,
            currentPeriodEnd: period.assembled.current.range.to ?? anchor,
            cut: cut,
            omslag: omslag,
            entity: entity
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
            entities: result.entities,
            overview: overview,
            filingReconciliation: filingReconciliation,
            acquired: acquired,
            period: period,
            costBreakdown: costBreakdown,
            kia: kia,
            equity: equity,
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
        // tz: TimeZone = .current,
        // calendar: Calendar = {
        //     var c = Calendar(identifier: .iso8601)
        //     c.firstWeekday = 2
        //     return c
        // }(),
        calendar: Calendar = periodCalendar(),
        cut: AssembleCut = .init(
            target: .L3,
            includeCodes: [],
            includeIntermediates: true,
            omitZerosBeyondLevel1: true
        ),
        omslag: OmslagMode = .apply,
        entity: BusinessEntity = .vof,
        equityComparePrevious: Bool = false,
        reconciliationTolerance: Decimal = 0,
        depreciationOptions: DepreciationAuditRunner.Options = .init(
            granularity: .monthly,
            tolerance: 0,
            tolerateAggregateIntraQuarter: true
        )
    ) async throws -> MetaAuditReport {
        let settings = try EntryCompilerSettingsLoader.load(from: projectRoot)

        let result = try await EntryCompileDriver.compile(
            projectRoot: projectRoot,
            setting: setting,
            verbose: verbose
        )

        return try run(
            result: result,
            settings: settings,
            shape: shape,
            anchor: anchor,
            // tz: tz,
            calendar: calendar,
            cut: cut,
            omslag: omslag,
            entity: entity,
            equityComparePrevious: equityComparePrevious,
            reconciliationTolerance: reconciliationTolerance,
            depreciationOptions: depreciationOptions
        )
    }

    private static func buildEquitySection(
        result: EntryCompileDriver.Result,
        settings: EntryCompilerSettings,
        kind: PeriodKind,
        comparePrevious: Bool,
        chart: CompiledChart,
        currentPeriodEnd: Date,
        cut: AssembleCut,
        omslag: OmslagMode,
        entity: BusinessEntity
    ) throws -> MetaAuditEquitySection {
        var equityCalendar = Calendar(identifier: .gregorian)
        equityCalendar.timeZone = settings.entry.defaultTimezone

        let assembleBundle: (Date, Date) throws -> StatementBundle = { periodStart, _ in
            try NativeBundleBuilder.buildPeriodBundle(
                result: result,
                kind: kind,
                anchor: periodStart,
                cut: cut,
                omslag: omslag,
                entity: entity
            )
        }

        let history = try OwnerEquity.Rollforward.history_from_inception(
            entries: result.entries,
            endAsOf: currentPeriodEnd,
            kind: kind,
            calendar: equityCalendar,
            settings: settings,
            assemble: assembleBundle
        )

        let view: ClosedRange<Int>? = {
            guard !history.isEmpty else {
                return nil
            }

            if kind == .lifetime {
                return 0...0
            }

            let anchorLabel = labelForPeriodStart(
                periodStart(
                    for: currentPeriodEnd,
                    kind: kind,
                    calendar: equityCalendar
                ),
                kind: kind,
                calendar: equityCalendar
            )

            guard let curIdx = history.firstIndex(where: { $0.label == anchorLabel }) else {
                return nil
            }

            let lo = max(0, curIdx - (comparePrevious ? 1 : 0))
            return lo...curIdx
        }()

        let title = "Equity (backsolved)"
        // let config = EquityRollforwardConfig()
        let config = try settings.makeEquityRollforwardConfig(entity: entity)

        let report = try EquityPresentation(
            reportTitle: title,
            config: config
        ).build(
            from: .init(
                chart: chart,
                history: history,
                entities: result.entities,
                view: view
            )
        )

        return .init(
            title: title,
            config: config,
            history: history,
            view: view,
            report: report
        )
    }
}
