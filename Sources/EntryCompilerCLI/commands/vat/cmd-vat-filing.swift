import Accounting
import AccountingCompiler
import Arguments
import Foundation
import Interfaces

extension VATCommand {
    enum Filing: ParsedArgumentCommand {
        typealias Options = VATFilingOptions

        static let name = "filing"

        static func run(
            _ options: VATFilingOptions,
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

            guard let anchorDate = period.windows.window.from else {
                throw EntryCompilerCLIError.validation(
                    "VAT filing requires a concrete quarter window."
                )
            }

            let targetPeriod = VATFilingBuilder.period(
                containing: anchorDate,
                calendar: calendar
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

            let status = try VATStatusBuilder.build(
                resolvedEntries: context.result.resolved,
                chart: native.chart,
                title: "VAT status – through \(periodLabel)",
                period: period.windows.window,
                tolerance: options.tolerance,
                calendar: calendar,
                businessEntity: .vof
            )

            let statusQuarter = status.quarters.first {
                $0.period == targetPeriod
            }

            let overview = try RGSAssembler.vatOverview(
                "BTW / Taxes Overview – \(periodLabel)",
                bundle: native.bundle,
                chart: native.chart,
                includeCorrections: true,
                minAbs: 0
            )

            let report = try VATFilingBuilder.build(
                resolvedEntries: context.result.resolved,
                chart: native.chart,
                window: period.windows.window,
                targetPeriod: targetPeriod,
                statusQuarter: statusQuarter,
                balanceSheetNetPosition: overview.netPosition,
                title: "VAT filing – \(periodLabel)",
                calendar: calendar,
                businessEntity: .vof
            )

            print(
                report.renderText(
                    .init(
                        title: report.title,
                        showSourceRows: !options.hideSourceRows,
                        fractionDigits: 2
                    )
                )
            )
        }
    }
}
