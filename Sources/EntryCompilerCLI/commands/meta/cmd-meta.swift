import Accounting
import Arguments
import Foundation
import Interfaces

enum MetaCommand: ArgumentCommand {
    static let name = "meta"
    static let defaultChild = Audit.self

    static let children: [ArgumentCommandType] = [
        Audit.self,
    ]

    struct Audit: ParsedArgumentCommand {
        typealias Options = MetaAuditOptions

        static let name = "audit"

        static func run(
            _ options: MetaAuditOptions,
            invocation: ParsedInvocation
        ) async throws {
            let context = try await EntryCompilerCommandContextBuilder.build(
                project: options.project,
                trace: options.trace,
                verbose: false
            )

            let period = try EntryCompilerPeriodResolver.anchor(
                options.period,
                timeZone: context.settings.entry.defaultTimezone
            )

            let calendar = periodCalendar(
                timeZone: context.settings.entry.defaultTimezone
            )

            let report = try MetaAuditRunner.run(
                result: context.result,
                settings: context.settings,
                shape: options.period.shape,
                anchor: period.anchor,
                calendar: calendar,
                cut: AssembleCut(
                    target: .L3,
                    includeCodes: [],
                    includeIntermediates: true,
                    omitZerosBeyondLevel1: true
                ),
                omslag: .apply,
                entity: .vof,
                equityComparePrevious: false,
                reconciliationTolerance: 0,
                depreciationOptions: .init(
                    granularity: .monthly,
                    tolerance: 0,
                    tolerateAggregateIntraQuarter: true,
                    calendar: calendar
                )
            )

            print("Meta audit")
            print("──────────")
            print("Project: \(context.root.path)")
            print("Period kind: \(options.period.kind.rawValue)")

            if let anchor = options.period.anchor {
                print("Anchor: \(anchor)")
            }

            print("")

            if let kiaWarning = report.kia.warning {
                print("warning: \(kiaWarning)")
                print("")
            }

            print(
                AssetViews.AssetsOverviewPrinter.renderText(
                    report.overview,
                    options: AssetsOverviewRenderOptions(
                        diagnostics: options.diagnostics,
                        showUnderlyingRows: true,
                        showOnlyFlaggedUnderlyingRows: false,
                        showZeroUnderlyingRows: false,
                        diagnosticsOnlyForFlaggedRows: true
                    )
                )
            )

            print("")
            print(
                AssetViews.AssetFilingReconciliationPrinter.renderText(
                    report.filingReconciliation
                )
            )

            print("")
            print(
                AssetViews.AcquiredAssetsPrinter.renderText(
                    report.acquired,
                    diagnostics: options.diagnostics
                )
            )

            print("")
            try ProjectionPipeline.render(
                report.period,
                as: .native,
                options: NativeRenderOptions(
                    caption: .label,
                    detail: .standard,
                    equityCode: "BEiv",
                    includeOtherBucket: false,
                    comparePrevious: false,
                    showRangeHeading: true
                ),
                showProjectionDiagnostics: false
            )

            print("")
            print(
                CostViews.CostBreakdownPrinter.renderText(
                    report.costBreakdown
                )
            )

            print("")
            try OwnerEquity.Rollforward.history(
                title: report.equity.title,
                allPeriods: report.equity.history,
                chart: report.period.chart,
                entities: context.result.entities,
                view: report.equity.view,
                config: report.equity.config
            )

            print("")
            print(
                report.depreciation.renderText(
                    DepreciationAuditTextOptions(
                        showPerYearAmounts: true,
                        showPerMonthAmounts: true,
                        showPerPeriodAmounts: false
                    )
                )
            )

            guard options.pdf.enabled else {
                return
            }

            let sourceAppendices = try makeMetaAuditSourceAppendices(
                root: context.root,
                requestedGroups: options.addGroup
            )

            let html = try MetaAuditHTMLRenderer.render(
                report: report,
                options: .init(
                    title: "Meta audit",
                    subtitle: report.period.assembled.current.range.string(),
                    company: context.settings.statementData?.company?.statementCompany,
                    currencySymbol: "€",
                    showStatementSummary: true,
                    showStatementRatios: true,
                    showAssetsDiagnostics: options.diagnostics,
                    showAssetsUnderlyingRows: true,
                    showAssetsOnlyFlaggedUnderlyingRows: false,
                    showAssetsZeroUnderlyingRows: false,
                    showAssetsReconciliation: true,
                    omitZeroOnlySupplementarySections: true,
                    showKIADiagnostics: options.diagnostics,
                    verboseKIA: options.verbose,
                    showEquityAnchorMessages: true,
                    showEquityDiagnostics: true,
                    showEquityAllocation: true,
                    showEquityDrawingsBreakdown: true,
                    showEquityUnassigned: true,
                    sourceAppendices: sourceAppendices
                )
            )

            let slug = "\(report.period.assembled.current.range.filenameSlug())-meta-audit"

            try EntryCompilerPDFWriter.write(
                root: context.root,
                filename: "\(slug).pdf",
                html: html,
                margins: options.pdf.margins
            )
        }

        private static func makeMetaAuditSourceAppendices(
            root: URL,
            requestedGroups rawGroups: [String]
        ) throws -> [MetaAuditHTMLRenderer.SourceAppendix] {
            let groups = ECSourceSelection.parseNormalizedGroupSelection(
                rawGroups
            )

            guard !groups.isEmpty else {
                return []
            }

            let project = EntryCompilerProject(
                root: root
            )

            let allFiles = try ECSourceSelection.collectFiles(
                root: root,
                scopeURLs: project.urls(.entries),
                explicitPaths: []
            )

            return try groups.map { group in
                let matchedFiles = ECSourceSelection.filterFiles(
                    allFiles,
                    matchingGroups: Set([group])
                )

                guard !matchedFiles.isEmpty else {
                    throw EntryCompilerCLIError.validation(
                        "No entry blocks matched requested group: \(group)"
                    )
                }

                let presentationOptions = ECSourcePresentationOptions(
                    title: "Attached EC source",
                    subtitle: "Group: \(group)",
                    showLineNumbers: true,
                    compact: true,
                    includeFileBlockCounts: true,
                    syntaxHighlighting: true
                )

                let document = ECSourcePresenter.present(
                    files: matchedFiles,
                    options: presentationOptions
                )

                return MetaAuditHTMLRenderer.SourceAppendix(
                    title: "Attached source – \(group)",
                    document: document,
                    presentationOptions: presentationOptions
                )
            }
        }
    }
}

struct MetaAuditOptions: Sendable, ArgumentParsed {
    typealias ArgumentPayload = Payload

    var project: ProjectOptions
    var period: EntryCompilerPeriodRequest
    var addGroup: [String]
    var pdf: PDFOptions
    var diagnostics: Bool
    var verbose: Bool
    var trace: Bool

    init(
        arguments: Payload
    ) throws {
        self.project = arguments.project
        self.period = try EntryCompilerPeriodRequest(
            arguments: arguments.period
        )
        self.addGroup = arguments.addGroup
        self.pdf = arguments.pdf
        self.diagnostics = arguments.diagnostics
        self.verbose = arguments.verbose
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
                "meta audit currently supports: year, quarter, month, week, lifetime."
            )
        }
    }

    struct Payload: ArgumentGroup {
        @Group("project")
        var project: ProjectOptions

        @Group("period")
        var period: EntryCompilerPeriodRequest.Options

        @Opts(
            "add-group",
            take: .many
        )
        var addGroup: [String]

        @Group("pdf")
        var pdf: PDFOptions

        @Flag("diagnostics")
        var diagnostics: Bool

        @Flag(
            "verbose",
            short: "v"
        )
        var verbose: Bool

        @Flag("trace")
        var trace: Bool

        init() {}
    }
}
