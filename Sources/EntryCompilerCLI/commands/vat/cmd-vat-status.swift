import Accounting
import AccountingCompiler
import Arguments
import Foundation
import Interfaces

extension VATCommand {
    enum Status: ParsedArgumentCommand {
        typealias Options = VATStatusOptions

        static let name = "status"

        static func run(
            _ options: VATStatusOptions,
            invocation: ParsedInvocation
        ) async throws {
            let context = try await EntryCompilerCommandContextBuilder.build(
                project: options.project,
                trace: options.trace
            )

            let period = try VATCommand.resolvePeriod(
                options.period,
                settings: context.settings
            )

            let calendar = periodCalendar(
                timeZone: context.settings.entry.defaultTimezone
            )

            let periodLabel = VATCommand.makePeriodLabel(
                request: options.period,
                period: period,
                settings: context.settings,
                calendar: calendar
            )

            let native = try NativeOutputBuilder.buildCompileOutput(
                result: context.result,
                cut: .init(
                    target: .L3,
                    includeCodes: [],
                    includeIntermediates: true,
                    omitZerosBeyondLevel1: true
                ),
                omslag: .apply,
                entity: .vof,
                autoClose: true
            )

            let report = try VATStatusBuilder.build(
                resolvedEntries: context.result.resolved,
                chart: native.chart,
                title: "VAT status – through \(periodLabel)",
                period: period.windows.window,
                tolerance: options.tolerance,
                calendar: calendar,
                businessEntity: .vof
            )

            print(
                report.renderText(
                    .init(
                        title: report.title,
                        showHeader: true,
                        showEntries: !options.hideEntries,
                        onlyFlagged: options.onlyFlagged,
                        fractionDigits: 2
                    )
                )
            )

            guard options.pdf.enabled else {
                return
            }

            let html = StatementHTMLRenderer.renderVATStatusHTML(
                report,
                options: .init(
                    title: "BTW-status – t/m \(periodLabel)",
                    subtitle: "Inception → \(period.windows.window.string())",
                    currencySymbol: "€",
                    showEntries: !options.hideEntries,
                    showOnlyFlagged: options.onlyFlagged
                )
            )

            let slug = VATCommand.makeVATSlug(
                request: options.period,
                period: period,
                settings: context.settings,
                calendar: calendar
            )

            try VATCommand.writePDF(
                root: context.root,
                filename: "vat-status-\(slug).pdf",
                html: html,
                margins: options.pdf.margins
            )
        }
    }
}
