import Accounting
import Foundation
import HTML
import CSS

public enum MetaAuditHTMLRenderer {
    public struct SourceAppendix: Sendable {
        public let title: String
        public let document: ECSourceDocument
        public let presentationOptions: ECSourcePresentationOptions

        public init(
            title: String,
            document: ECSourceDocument,
            presentationOptions: ECSourcePresentationOptions = .init()
        ) {
            self.title = title
            self.document = document
            self.presentationOptions = presentationOptions
        }
    }

    public struct Options: Sendable {
        public var title: String
        public var subtitle: String?
        public var company: StatementHTMLRenderer.Company?
        public var currencySymbol: String

        public var showStatementSummary: Bool
        public var showStatementRatios: Bool
        public var showStatementAverages: Bool

        public var showAssetsDiagnostics: Bool
        public var showAssetsUnderlyingRows: Bool
        public var showAssetsOnlyFlaggedUnderlyingRows: Bool
        public var showAssetsZeroUnderlyingRows: Bool
        public var showAssetsReconciliation: Bool
        public var omitZeroOnlySupplementarySections: Bool

        public var showKIADiagnostics: Bool
        public var verboseKIA: Bool

        public var showEquityAnchorMessages: Bool
        public var showEquityDiagnostics: Bool
        public var showEquityAllocation: Bool
        public var showEquityDrawingsBreakdown: Bool
        public var showEquityUnassigned: Bool

        public var sourceAppendices: [SourceAppendix]

        public init(
            title: String = "Meta audit",
            subtitle: String? = nil,
            company: StatementHTMLRenderer.Company? = nil,
            currencySymbol: String = "€",
            showStatementSummary: Bool = true,
            showStatementRatios: Bool = true,
            showStatementAverages: Bool = true,
            showAssetsDiagnostics: Bool = true,
            showAssetsUnderlyingRows: Bool = true,
            showAssetsOnlyFlaggedUnderlyingRows: Bool = false,
            showAssetsZeroUnderlyingRows: Bool = false,
            showAssetsReconciliation: Bool = true,
            omitZeroOnlySupplementarySections: Bool = true,
            showKIADiagnostics: Bool = true,
            verboseKIA: Bool = false,
            showEquityAnchorMessages: Bool = true,
            showEquityDiagnostics: Bool = true,
            showEquityAllocation: Bool = true,
            showEquityDrawingsBreakdown: Bool = true,
            showEquityUnassigned: Bool = true,
            sourceAppendices: [SourceAppendix] = []
        ) {
            self.title = title
            self.subtitle = subtitle
            self.company = company
            self.currencySymbol = currencySymbol

            self.showStatementSummary = showStatementSummary
            self.showStatementRatios = showStatementRatios
            self.showStatementAverages = showStatementAverages

            self.showAssetsDiagnostics = showAssetsDiagnostics
            self.showAssetsUnderlyingRows = showAssetsUnderlyingRows
            self.showAssetsOnlyFlaggedUnderlyingRows = showAssetsOnlyFlaggedUnderlyingRows
            self.showAssetsZeroUnderlyingRows = showAssetsZeroUnderlyingRows
            self.showAssetsReconciliation = showAssetsReconciliation
            self.omitZeroOnlySupplementarySections = omitZeroOnlySupplementarySections

            self.showKIADiagnostics = showKIADiagnostics
            self.verboseKIA = verboseKIA

            self.showEquityAnchorMessages = showEquityAnchorMessages
            self.showEquityDiagnostics = showEquityDiagnostics
            self.showEquityAllocation = showEquityAllocation
            self.showEquityDrawingsBreakdown = showEquityDrawingsBreakdown
            self.showEquityUnassigned = showEquityUnassigned

            self.sourceAppendices = sourceAppendices
        }
    }

    public static func render(
        report: MetaAuditReport,
        options: Options = .init()
    ) throws -> String {
        let subtitle = options.subtitle ?? report.period.assembled.current.range.string()
        let css = buildStyleSheet().render()

        let statementNodes = try makeComparativeStatementNodes(
            report: report,
            options: options
        )

        let costBreakdownNodes = makeCostBreakdownNodes(
            report: report,
            options: options
        )

        let assetsNodes = makeAssetsOverviewNodes(
            report: report,
            options: options
        )

        let kiaNodes = makeKIANodes(
            report: report,
            options: options
        )

        let equityNodes = makeEquityOverviewNodes(
            report: report,
            subtitle: subtitle,
            options: options
        )

        let sourceAppendices = options.sourceAppendices

        let doc = HTML.document {
            HTML.html(["lang": "nl"]) {
                HTML.head {
                    HTML.meta(.charset())
                    HTML.meta(.viewport())
                    HTML.title(options.title)
                    HTML.style(css)
                }

                HTML.body(["class": "sr-meta-audit"]) {
                    renderMetaAuditHeader(
                        title: options.title,
                        subtitle: subtitle
                    )

                    renderMetaAuditSection(
                        title: "Financiëel verslag"
                    ) {
                        statementNodes
                    }

                    renderMetaAuditSection(
                        title: report.costBreakdown.title,
                        pageBreak: true
                    ) {
                        costBreakdownNodes
                    }

                    renderMetaAuditSection(
                        title: "Assets filing overview",
                        pageBreak: true
                    ) {
                        assetsNodes
                    }

                    renderMetaAuditSection(
                        title: "KIA overview",
                        pageBreak: true
                    ) {
                        kiaNodes
                    }

                    renderMetaAuditSection(
                        title: report.equity.title,
                        pageBreak: true
                    ) {
                        equityNodes
                    }

                    for appendix in sourceAppendices {
                        renderMetaAuditSection(
                            title: appendix.title,
                            pageBreak: true
                        ) {
                            makeSourceAppendixNodes(
                                appendix
                            )
                        }
                    }
                }
            }
        }

        // return doc.render(default: .pretty, doctype: true)

        // '.minified' fixes appendices rendering:
        return doc.render(default: .minified, doctype: true)
    }

    private static func buildStyleSheet() -> CSSStyleSheet {
        let local = CSSStyleSheet(
            rules: [
                CSS.rule(
                    "body.sr-meta-audit",
                    CSS.decl("background", "#fff")
                ),
                CSS.rule(
                    ".sr-meta-audit-header",
                    CSS.decl("margin-bottom", "24px")
                ),
                CSS.rule(
                    ".sr-meta-audit-fragment + .sr-meta-audit-fragment",
                    CSS.decl("margin-top", "24px")
                ),
                CSS.rule(
                    ".sr-meta-audit-fragment.page-break-before",
                    CSS.decl("break-before", "page")
                ),
                CSS.rule(
                    ".sr-meta-audit-fragment-title",
                    CSS.decl("display", "none")
                ),

                CSS.rule(
                    ".sr-meta-audit-note",
                    CSS.decl("padding", "12px 14px"),
                    CSS.decl("border-radius", "8px"),
                    CSS.decl("margin", "8px 0 0 0")
                ),
                CSS.rule(
                    ".sr-meta-audit-note-warning",
                    CSS.decl("border", "1px solid #d6c27a"),
                    CSS.decl("background", "#fff8e1"),
                    CSS.decl("color", "#5c4b00")
                ),
            ]
        )

        return CSSStyleSheet.merged([
            StatementStyleCSS.base(),
            StatementStyleCSS.assetsShares(),
            StatementStyleCSS.costBreakdown(),
            ECSourceHTMLRendererCSS.base(compact: true),
            local
        ])
    }

    @HTMLBuilder
    private static func renderMetaAuditHeader(
        title: String,
        subtitle: String?
    ) -> [any HTMLNode] {
        HTML.header(["class": "sr-meta-audit-header"]) {
            HTML.h1 {
                HTML.text(title)
            }

            if let subtitle {
                HTML.div(["class": "subtitle"]) {
                    HTML.text(subtitle)
                }
            }
        }
    }

    @HTMLBuilder
    private static func renderMetaAuditSection(
        title: String,
        pageBreak: Bool = false,
        @HTMLBuilder content: () -> [any HTMLNode]
    ) -> [any HTMLNode] {
        let className = pageBreak
            ? "sr-meta-audit-fragment page-break-before"
            : "sr-meta-audit-fragment"

        HTML.section(["class": className]) {
            HTML.h2(["class": "sr-meta-audit-fragment-title"]) {
                HTML.text(title)
            }

            content()
        }
    }

    private static func makeComparativeStatementNodes(
        report: MetaAuditReport,
        options: Options
    ) throws -> [any HTMLNode] {
        let statementOptions = StatementHTMLRenderer.Options(
            title: "Financiëel verslag",
            subtitle: report.period.assembled.current.range.string(),
            currencySymbol: options.currencySymbol,
            minAbsIncome: 0,
            includeOtherBucket: false,
            omitIncomeLevel1Root: true,
            company: options.company,
            hierarchyPrefixStyle: .spacing,
            showRatios: options.showStatementRatios,
            showAverages: options.showStatementAverages,
            periodShape: report.period.shape
        )

        var nodes: [any HTMLNode] = []
        nodes.append(contentsOf: StatementHTMLRenderer.renderDocumentHeader(options: statementOptions))

        guard let previous = report.period.assembled.previous else {
            let model = try StatementHTMLRenderer.buildDocumentModel(
                bundle: report.period.assembled.current.bundle,
                chart: report.period.chart,
                equityCode: "BEiv",
                options: statementOptions
            )

            nodes.append(contentsOf: StatementHTMLRenderer.renderTableSection(
                model.income,
                options: statementOptions
            ))

            for section in model.balances {
                nodes.append(contentsOf: StatementHTMLRenderer.renderTableSection(
                    section,
                    options: statementOptions
                ))
            }

            if options.showStatementSummary {
                nodes.append(contentsOf: StatementHTMLRenderer.renderSummary(model.summary))
            }

            if options.showStatementRatios {
                nodes.append(contentsOf: StatementHTMLRenderer.renderRatiosSection(model.ratios))
            }

            if options.showStatementAverages {
                nodes.append(
                    contentsOf: StatementHTMLRenderer.renderAveragesSection(model.averages))
            }

            return nodes
        }

        let comparativeModel = try StatementHTMLRenderer.buildComparativeDocumentModel(
            currentBundle: report.period.assembled.current.bundle,
            previousBundle: previous.bundle,
            chart: report.period.chart,
            equityCode: "BEiv",
            currentColumnTitle: StatementHTMLRenderer.comparativeColumnTitle(
                for: report.period.assembled.current
            ),
            previousColumnTitle: StatementHTMLRenderer.comparativeColumnTitle(
                for: previous
            ),
            options: statementOptions
        )

        nodes.append(contentsOf: StatementHTMLRenderer.renderComparativeTableSection(
            comparativeModel.income,
            options: statementOptions
        ))

        for section in comparativeModel.balances {
            nodes.append(contentsOf: StatementHTMLRenderer.renderComparativeTableSection(
                section,
                options: statementOptions
            ))
        }

        if options.showStatementSummary {
            nodes.append(contentsOf: StatementHTMLRenderer.renderComparativeSummary(
                comparativeModel.summary
            ))
        }

        if options.showStatementRatios {
            nodes.append(contentsOf: StatementHTMLRenderer.renderComparativeRatiosSection(
                comparativeModel.ratios
            ))
        }

        if options.showStatementAverages {
            nodes.append(contentsOf: StatementHTMLRenderer.renderComparativeAveragesSection(
                comparativeModel.averages
            ))
        }

        return nodes
    }

    @HTMLBuilder
    private static func makeAssetsOverviewNodes(
        report: MetaAuditReport,
        options: Options
    ) -> [any HTMLNode] {
        HTML.div(["class": "sr-assets"]) {
            StatementHTMLRenderer.renderAssetsOverviewBody(
                overview: report.overview,
                reconciliation: report.filingReconciliation,
                options: .init(
                    title: "Assets filing overview",
                    subtitle: report.overview.period.string(),
                    currencySymbol: options.currencySymbol,
                    showDiagnostics: options.showAssetsDiagnostics,
                    showUnderlyingRows: options.showAssetsUnderlyingRows,
                    showOnlyFlaggedUnderlyingRows: options.showAssetsOnlyFlaggedUnderlyingRows,
                    showZeroUnderlyingRows: options.showAssetsZeroUnderlyingRows,
                    showReconciliation: options.showAssetsReconciliation,
                    omitZeroOnlySupplementarySections: options.omitZeroOnlySupplementarySections
                )
            )
        }
    }

    @HTMLBuilder
    private static func makeKIANodes(
        report: MetaAuditReport,
        options: Options
    ) -> [any HTMLNode] {
        HTML.div(["class": "sr-kia"]) {
            if let kia = report.kia.result {
                KIARenderer.renderBody(
                    kia,
                    title: "KIA \(report.kia.taxYear)",
                    subtitle: "Kleinschaligheidsinvesteringsaftrek",
                    verbose: options.verboseKIA,
                    diagnostics: options.showKIADiagnostics,
                    currencySymbol: options.currencySymbol
                )
            } else {
                HTML.div(["class": "sr-meta-audit-note sr-meta-audit-note-warning"]) {
                    HTML.h3 {
                        HTML.text("KIA \(report.kia.taxYear)")
                    }

                    HTML.p {
                        HTML.text(
                            report.kia.warning
                            ?? "KIA section unavailable."
                        )
                    }
                }
            }
        }
    }

    @HTMLBuilder
    private static func makeEquityOverviewNodes(
        report: MetaAuditReport,
        subtitle: String,
        options: Options
    ) -> [any HTMLNode] {
        HTML.div(["class": "sr-eq"]) {
            StatementHTMLRenderer.renderEquityOverviewBody(
                report: report.equity.report,
                entities: report.entities,
                config: report.equity.config,
                options: .init(
                    title: report.equity.title,
                    subtitle: subtitle,
                    showAnchorMessages: options.showEquityAnchorMessages,
                    showDiagnostics: options.showEquityDiagnostics,
                    showAllocation: options.showEquityAllocation,
                    showDrawingsBreakdown: options.showEquityDrawingsBreakdown,
                    showUnassignedEquity: options.showEquityUnassigned
                )
            )
        }
    }

    @HTMLBuilder
    private static func makeCostBreakdownNodes(
        report: MetaAuditReport,
        options: Options
    ) -> [any HTMLNode] {
        HTML.div(["class": "sr-cost-breakdown"]) {
            StatementHTMLRenderer.renderCostBreakdownBody(
                report: report.costBreakdown,
                options: .init(
                    title: report.costBreakdown.title,
                    subtitle: report.costBreakdown.period.string(),
                    currencySymbol: options.currencySymbol,
                    showMembers: true,
                    omitZeroMembers: true,
                    showReconciliation: true
                )
            )
        }
    }

    @HTMLBuilder
    private static func makeSourceAppendixNodes(
        _ appendix: SourceAppendix
    ) -> [any HTMLNode] {
        HTML.div(["class": "sr-meta-audit-source"]) {
            HTML.h2(["class": "sr-meta-audit-source-title"]) {
                HTML.text(appendix.document.title)
            }

            if let subtitle = appendix.document.subtitle,
               !subtitle.isEmpty {
                HTML.div(["class": "subtitle"]) {
                    HTML.text(subtitle)
                }
            }

            for file in appendix.document.files {
                ECSourceHTMLRenderer.renderFile(
                    file,
                    options: appendix.presentationOptions
                )
            }
        }
    }
}
