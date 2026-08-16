import Accounting
import AccountingCompiler
import Arguments
import Foundation
import Interfaces

enum EquityCommand: ParsedArgumentCommand {
    typealias Options = EquityCommandOptions

    static let name = "equity"

    static func run(
        _ options: EquityCommandOptions,
        invocation: ParsedInvocation
    ) async throws {
        try await EquityCommandRunner.run(
            options
        )
    }
}

enum EquityCommandRunner {
    static func run(
        _ options: EquityCommandOptions
    ) async throws {
        let context = try await EntryCompilerCommandContextBuilder.build(
            project: options.project,
            trace: options.trace
        )

        let period = try EntryCompilerPeriodResolver.anchor(
            options.period,
            timeZone: context.settings.entry.defaultTimezone
        )

        let calendar = periodCalendar(
            timeZone: context.settings.entry.defaultTimezone
        )

        let native = try NativeOutputBuilder.buildPeriodOutput(
            result: context.result,
            shape: options.period.shape,
            anchor: period.anchor,
            cut: AssembleCut(
                target: .L3,
                includeCodes: [],
                includeIntermediates: true,
                omitZerosBeyondLevel1: true
            ),
            omslag: .apply,
            entity: .vof,
            calendar: calendar
        )

        let chart = native.chart
        let selectedRangeLabel = native.assembled.current.range.string()

        if options.history {
            print("Anchor period: \(selectedRangeLabel)")
        } else {
            print(selectedRangeLabel)
        }

        do {
            try RGSAssembler.assertBalancedByL2(
                chart: chart,
                bundle: native.assembled.current.bundle,
                equityCode: "BEiv"
            )
        } catch {
            fputs(
                "warning: \(error)\n",
                stderr
            )
        }

        let targetPeriodEnd = native.assembled.current.range.to ?? Date()
        let rollforwardCalendar = Calendar(identifier: .gregorian)

        let allPeriods: [EquityPeriod]

        if options.useAsync {
            let assembleBundleAsync: @Sendable (Date, Date) async throws -> StatementBundle = { periodStart, _ in
                try await NativeBundleBuilder.buildPeriodBundleAsync(
                    result: context.result,
                    kind: options.period.kind,
                    anchor: periodStart,
                    cut: AssembleCut(
                        target: .L3,
                        includeCodes: [],
                        includeIntermediates: true,
                        omitZerosBeyondLevel1: true
                    ),
                    omslag: .apply,
                    entity: .vof
                )
            }

            allPeriods = try await OwnerEquity.Rollforward.history_from_inception_async(
                entries: context.result.entries,
                endAsOf: targetPeriodEnd,
                kind: options.period.kind,
                calendar: rollforwardCalendar,
                settings: context.settings,
                assemble_async: assembleBundleAsync
            )
        } else {
            let assembleBundle: (Date, Date) throws -> StatementBundle = { periodStart, _ in
                try NativeBundleBuilder.buildPeriodBundle(
                    result: context.result,
                    kind: options.period.kind,
                    anchor: periodStart,
                    cut: AssembleCut(
                        target: .L3,
                        includeCodes: [],
                        includeIntermediates: true,
                        omitZerosBeyondLevel1: true
                    ),
                    omslag: .apply,
                    entity: .vof
                )
            }

            allPeriods = try OwnerEquity.Rollforward.history_from_inception(
                entries: context.result.entries,
                endAsOf: targetPeriodEnd,
                kind: options.period.kind,
                calendar: rollforwardCalendar,
                settings: context.settings,
                assemble: assembleBundle
            )
        }

        let anchorLabel = labelForPeriodStart(
            periodStart(
                for: targetPeriodEnd,
                kind: options.period.kind,
                calendar: rollforwardCalendar
            ),
            kind: options.period.kind,
            calendar: rollforwardCalendar
        )

        let config = try context.settings.makeEquityRollforwardConfig(
            entity: .vof
        )

        if options.compare {
            fputs(
                "warning: --compare is deprecated and ignored; use --history to render the full equity history.\n",
                stderr
            )
        }

        let renderView: ClosedRange<Int>? = {
            guard !options.history else {
                return nil
            }

            guard let currentIndex = allPeriods.firstIndex(where: { $0.label == anchorLabel }) else {
                return nil
            }

            return currentIndex...currentIndex
        }()

        if options.useAsync {
            try await OwnerEquity.Rollforward.history_async(
                title: "Equity (backsolved)",
                allPeriods: allPeriods,
                chart: chart,
                entities: context.result.entities,
                view: renderView,
                config: config,
                afterEachPeriod: { period, owners, deltas, config in
                    printDrawingsBreakdownIfAvailable(
                        period: period,
                        chart: chart,
                        entities: context.result.entities,
                        owners: owners,
                        deltas: deltas,
                        config: config
                    )
                }
            )
        } else {
            try OwnerEquity.Rollforward.history(
                title: "Equity (backsolved)",
                allPeriods: allPeriods,
                chart: chart,
                entities: context.result.entities,
                view: renderView,
                config: config,
                afterEachPeriod: { period, owners, deltas, config in
                    printDrawingsBreakdownIfAvailable(
                        period: period,
                        chart: chart,
                        entities: context.result.entities,
                        owners: owners,
                        deltas: deltas,
                        config: config
                    )
                }
            )
        }

        guard options.pdf else {
            return
        }

        let htmlTitle = "Equity (backsolved)"
        let htmlSubtitle = options.history
            ? "History through \(selectedRangeLabel)"
            : selectedRangeLabel

        let report = try EquityPresentation(
            reportTitle: htmlTitle,
            config: config
        ).build(
            from: .init(
                chart: chart,
                history: allPeriods,
                entities: context.result.entities,
                view: renderView
            )
        )

        let html = try StatementHTMLRenderer.renderEquityOverviewHTML(
            report: report,
            entities: context.result.entities,
            config: config,
            options: .init(
                title: htmlTitle,
                subtitle: htmlSubtitle,
                showAnchorMessages: true,
                showDiagnostics: true,
                showAllocation: true,
                showDrawingsBreakdown: true,
                showUnassignedEquity: true
            )
        )

        let slug = [
            native.assembled.current.range.filenameSlug(),
            "equity",
            options.history ? "history" : nil,
        ]
        .compactMap { $0 }
        .joined(separator: "-")

        try await EntryCompilerPDFWriter.write(
            root: context.root,
            filename: "\(slug).pdf",
            html: html,
            margins: 40
        )
    }

    private static func printDrawingsBreakdownIfAvailable(
        period: EquityPeriod,
        chart: CompiledChart,
        entities: EntityStore,
        owners: [Int],
        deltas: [Int: OwnerDelta],
        config: EquityRollforwardConfig
    ) {
        debugUnassignedEquity(
            period,
            chart: chart,
            cfg: config
        )

        let breakdown = buildDrawingsBreakdown(
            bundle: period.bundle,
            chart: chart,
            groups: config.defaultDrawingGroups
        )

        guard let drawingsReport = try? makeEquityDrawingsBreakdownReport(
            breakdown: breakdown,
            owners: owners,
            deltas: deltas,
            asOf: period.asOf,
            entities: entities,
            digits: config.fractionDigits
        ) else {
            return
        }

        printDrawingsBreakdown(
            title: "Onttrekkingen – detail per post",
            entities: entities,
            cfg: config,
            report: drawingsReport
        )
    }
}
