import Accounting
import AccountingCompiler
import Arguments
import Foundation
import Interfaces

extension VATCommand {
    enum Overview: ParsedArgumentCommand {
        typealias Options = VATOverviewOptions

        static let name = "overview"

        static func run(
            _ options: VATOverviewOptions,
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

            let native = try NativeOutputBuilder.buildWindowOutput(
                result: context.result,
                windows: period.windows,
                shape: period.effectiveShape,
                cut: .init(
                    target: .L3,
                    includeCodes: [],
                    includeIntermediates: true,
                    omitZerosBeyondLevel1: true
                ),
                omslag: .apply,
                entity: .vof,
                calendar: calendar
            )

            try RGSPrinter.vatOverview(
                "BTW / Taxes Overview – \(periodLabel)",
                bundle: native.bundle,
                chart: native.chart,
                includeCorrections: options.includeCorrections,
                minAbs: 0
            )

            guard options.pdf.enabled else {
                return
            }

            let html = try StatementHTMLRenderer.renderVATOverviewHTML(
                bundle: native.bundle,
                chart: native.chart,
                options: .init(
                    title: "BTW-overzicht – \(periodLabel)",
                    subtitle: period.windows.window.string(),
                    currencySymbol: "€"
                ),
                includeCorrections: options.includeCorrections,
                minAbs: 0
            )

            let slug = VATCommand.makeVATSlug(
                request: options.period,
                period: period,
                settings: context.settings,
                calendar: calendar
            )

            try await VATCommand.writePDF(
                root: context.root,
                filename: "vat-\(slug).pdf",
                html: html,
                margins: options.pdf.margins
            )
        }
    }
}
