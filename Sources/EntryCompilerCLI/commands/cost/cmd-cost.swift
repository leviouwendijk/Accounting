import Accounting
import AccountingCompiler
import Arguments
import Foundation
import Interfaces

enum CostCommand: ArgumentCommand {
    static let name = "cost"
    static let defaultChild = Breakdown.self

    static let children: [ArgumentCommandType] = [
        Breakdown.self,
    ]

    struct Breakdown: ParsedArgumentCommand {
        typealias Options = CostBreakdownOptions

        static let name = "breakdown"

        static func run(
            _ options: CostBreakdownOptions,
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

            let current = try NativeOutputBuilder.buildPeriodOutput(
                result: context.result,
                shape: period.effectiveShape,
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

            let report = try CostViews.CostBreakdownBuilder.build(
                period: current.assembled.current.range,
                chart: current.chart,
                bundle: current.assembled.current.bundle,
                omslag: .apply,
                tolerance: 0
            )

            print(
                CostViews.CostBreakdownPrinter.renderText(
                    report
                )
            )

            guard options.pdf.enabled else {
                return
            }

            let html = StatementHTMLRenderer.renderCostBreakdownHTML(
                report: report,
                options: .init(
                    title: report.title,
                    subtitle: report.period.string(),
                    currencySymbol: "€",
                    showMembers: true,
                    omitZeroMembers: true,
                    showReconciliation: true
                )
            )

            try await EntryCompilerPDFWriter.write(
                root: context.root,
                filename: "\(current.assembled.current.range.filenameSlug())-cost-breakdown.pdf",
                html: html,
                margins: options.pdf.margins
            )
        }
    }
}

struct CostBreakdownOptions: Sendable, ArgumentParsed {
    typealias ArgumentPayload = Payload

    var project: ProjectOptions
    var period: EntryCompilerPeriodRequest
    var pdf: PDFOptions
    var trace: Bool

    init(
        arguments: Payload
    ) throws {
        self.project = arguments.project
        self.period = try EntryCompilerPeriodRequest(
            arguments: arguments.period
        )
        self.pdf = arguments.pdf
        self.trace = arguments.trace

        try validatePeriod(
            period.kind
        )
    }

    private func validatePeriod(
        _ kind: PeriodKind
    ) throws {
        let supported: Set<PeriodKind> = [
            .year,
            .quarter,
            .month,
            .week,
            .lifetime,
        ]

        guard supported.contains(kind) else {
            throw EntryCompilerCLIError.validation(
                "cost breakdown currently supports: year, quarter, month, week, lifetime."
            )
        }
    }

    struct Payload: ArgumentGroup {
        @Group("project")
        var project: ProjectOptions

        @Group("period")
        var period: EntryCompilerPeriodRequest.Options

        @Group("pdf")
        var pdf: PDFOptions

        @Flag("trace")
        var trace: Bool

        init() {}
    }
}
