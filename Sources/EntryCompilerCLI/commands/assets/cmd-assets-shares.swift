import Accounting
import AccountingCompiler
import Arguments
import Foundation
import Interfaces

enum AssetsSharesCommand: ParsedArgumentCommand {
    typealias Options = AssetsSharesOptions

    static let name = "shares"

    static func run(
        _ options: AssetsSharesOptions,
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

        let report = try AssetViews.AssetSharesHistoryBuilder.build(
            result: context.result,
            kind: options.period.kind,
            anchor: period.anchor,
            customFrom: period.customFrom,
            customTo: period.customTo,
            includeHistory: options.history && options.period.kind == .year,
            calendar: calendar
        )

        print(
            AssetViews.AssetSharesHistoryPrinter.renderText(
                report
            )
        )

        guard options.pdf.enabled else {
            return
        }

        let html = StatementHTMLRenderer.renderAssetsSharesHTML(
            report: report,
            options: .init(
                title: "Aandelen in activa",
                subtitle: report.title,
                currencySymbol: "€"
            )
        )

        let slug = EntryCompilerSlugs.assetsShares(
            kind: options.period.kind,
            history: options.history,
            window: period.windows.window,
            timeZone: context.settings.entry.defaultTimezone
        )

        try EntryCompilerPDFWriter.write(
            root: context.root,
            filename: "\(slug).pdf",
            html: html,
            margins: options.pdf.margins
        )
    }
}
