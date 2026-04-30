import Accounting
import Arguments
import Foundation
import Interfaces

enum PeriodCommand: ParsedArgumentCommand {
    typealias Options = PeriodCommandOptions

    static let name = "period"

    static func run(
        _ options: PeriodCommandOptions,
        invocation: ParsedInvocation
    ) async throws {
        try await PeriodCommandRunner.run(
            options
        )
    }
}

enum PeriodCommandRunner {
    static func run(
        _ options: PeriodCommandOptions
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

        if options.hierarchyDiagnostics {
            let project = EntryCompilerProject(
                root: context.root
            )

            let diagnostics = try RGSHierarchyDiagnostics.run(
                project: project,
                settings: context.settings
            )

            print("")

            RGSHierarchyDiagnostics.print(
                diagnostics,
                title: "RGS hierarchy diagnostics",
                limit: 200
            )
        }

        if options.analyticsDiagnostics,
           let analytics = native.assembled.current.bundle.analytics {
            RGSAssembler.printAnalyticsDiagnostics(
                analytics
            )
        }

        let projectionKind = try EntryCompilerProjection.resolve(
            taxonomy: options.projection.taxonomy,
            presentation: options.projection.presentation,
            projectionDiagnostics: options.projection.projectionDiagnostics
        )

        try ProjectionPipeline.render(
            native,
            as: projectionKind,
            options: NativeRenderOptions(
                caption: options.presentation.caption,
                detail: options.presentation.detail,
                equityCode: "BEiv",
                includeOtherBucket: false,
                comparePrevious: false,
                showRangeHeading: true,
                showEntityBreakdown: options.byEntity
            ),
            showProjectionDiagnostics: options.projection.projectionDiagnostics
        )

        guard options.pdf.enabled else {
            return
        }

        let htmlTitle = "Financiëel verslag"
        let html: String

        if options.compare,
           let previous = native.assembled.previous {
            html = try StatementHTMLRenderer.renderComparative(
                current: native.assembled.current,
                previous: previous,
                chart: native.chart,
                currentColumnTitle: native.assembled.current.range.string(),
                previousColumnTitle: previous.range.string(),
                options: .init(
                    title: htmlTitle,
                    subtitle: native.assembled.current.range.string(),
                    includeOtherBucket: false,
                    company: context.settings.statementData?.company?.statementCompany,
                    periodShape: native.shape
                )
            )
        } else {
            html = try StatementHTMLRenderer.render(
                period: native.assembled.current,
                chart: native.chart,
                options: .init(
                    title: htmlTitle,
                    includeOtherBucket: false,
                    company: context.settings.statementData?.company?.statementCompany,
                    periodShape: native.shape
                )
            )
        }

        let slug = native.assembled.current.range.filenameSlug()

        try EntryCompilerPDFWriter.write(
            root: context.root,
            filename: "\(slug).pdf",
            html: html,
            margins: options.pdf.margins
        )
    }
}
