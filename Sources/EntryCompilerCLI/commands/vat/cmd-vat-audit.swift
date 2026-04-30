import Accounting
import Arguments
import Foundation
import Interfaces

extension VATCommand {
    enum Audit: ParsedArgumentCommand {
        typealias Options = VATAuditOptions

        static let name = "audit"

        static func run(
            _ options: VATAuditOptions,
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

            let report = VATAuditBuilder.build(
                resolvedEntries: context.result.resolved,
                title: "VAT audit trail – \(periodLabel)",
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

            let html = StatementHTMLRenderer.renderVATAuditHTML(
                report,
                options: .init(
                    title: "BTW-auditspoor – \(periodLabel)",
                    subtitle: period.windows.window.string(),
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
                filename: "vat-audit-\(slug).pdf",
                html: html,
                margins: options.pdf.margins
            )
        }
    }
}
