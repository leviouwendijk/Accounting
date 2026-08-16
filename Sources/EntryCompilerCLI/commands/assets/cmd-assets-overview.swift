import Accounting
import AccountingCompiler
import Arguments
import Foundation
import Interfaces

enum AssetsOverviewCommand: ParsedArgumentCommand {
    typealias Options = AssetsOverviewOptions

    static let name = "overview"

    static func run(
        _ options: AssetsOverviewOptions,
        invocation: ParsedInvocation
    ) async throws {
        let context = try await EntryCompilerCommandContextBuilder.build(
            project: options.project,
            trace: options.trace
        )

        let period = try EntryCompilerPeriodResolver.resolve(
            options.period,
            timeZone: context.settings.entry.defaultTimezone
        )

        let calendar = periodCalendar(
            timeZone: context.settings.entry.defaultTimezone
        )

        let overview = try AssetViews.AssetsOverviewBuilder.build(
            result: context.result,
            period: period.windows.window,
            calendar: calendar
        )

        print(
            AssetViews.AssetsOverviewPrinter.renderText(
                overview,
                options: AssetsOverviewRenderOptions(
                    diagnostics: options.diagnostics,
                    showUnderlyingRows: true,
                    showOnlyFlaggedUnderlyingRows: false,
                    showZeroUnderlyingRows: false,
                    diagnosticsOnlyForFlaggedRows: true
                )
            )
        )

        let current = try NativeOutputBuilder.buildWindowOutput(
            result: context.result,
            windows: period.windows,
            shape: period.effectiveShape,
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

        let reconciliation = AssetViews.AssetFilingReconciliationBuilder.build(
            overview: overview,
            chart: current.chart,
            bundle: current.bundle,
            tolerance: 0
        )

        print("")
        print(
            AssetViews.AssetFilingReconciliationPrinter.renderText(
                reconciliation
            )
        )

        guard options.pdf.enabled else {
            return
        }

        let html = StatementHTMLRenderer.renderAssetsOverviewHTML(
            overview: overview,
            reconciliation: reconciliation,
            options: .init(
                title: "Assets filing overview",
                subtitle: overview.period.string(),
                currencySymbol: "€",
                showDiagnostics: options.diagnostics,
                showUnderlyingRows: true,
                showOnlyFlaggedUnderlyingRows: false,
                showZeroUnderlyingRows: false,
                showReconciliation: true
            )
        )

        let slug = EntryCompilerSlugs.assetsOverview(
            kind: options.period.kind,
            toDate: options.period.toDate,
            window: period.windows.window,
            timeZone: context.settings.entry.defaultTimezone
        )

        try await EntryCompilerPDFWriter.write(
            root: context.root,
            filename: "\(slug).pdf",
            html: html,
            margins: options.pdf.margins
        )
    }
}
