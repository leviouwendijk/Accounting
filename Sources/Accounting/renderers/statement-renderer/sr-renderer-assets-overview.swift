import Foundation
import HTML

public extension StatementHTMLRenderer {
    struct AssetsOverviewOptions: Sendable {
        public var title: String
        public var subtitle: String?
        public var currencySymbol: String
        public var showDiagnostics: Bool
        public var showUnderlyingRows: Bool
        public var showOnlyFlaggedUnderlyingRows: Bool
        public var showZeroUnderlyingRows: Bool
        public var showReconciliation: Bool
        public var omitZeroOnlySupplementarySections: Bool

        public init(
            title: String = "Assets filing overview",
            subtitle: String? = nil,
            currencySymbol: String = "€",
            showDiagnostics: Bool = false,
            showUnderlyingRows: Bool = true,
            showOnlyFlaggedUnderlyingRows: Bool = false,
            showZeroUnderlyingRows: Bool = false,
            showReconciliation: Bool = true,
            omitZeroOnlySupplementarySections: Bool = true
        ) {
            self.title = title
            self.subtitle = subtitle
            self.currencySymbol = currencySymbol
            self.showDiagnostics = showDiagnostics
            self.showUnderlyingRows = showUnderlyingRows
            self.showOnlyFlaggedUnderlyingRows = showOnlyFlaggedUnderlyingRows
            self.showZeroUnderlyingRows = showZeroUnderlyingRows
            self.showReconciliation = showReconciliation
            self.omitZeroOnlySupplementarySections = omitZeroOnlySupplementarySections
        }
    }

    static func renderAssetsOverviewHTML(
        overview: AssetsOverview,
        reconciliation: AssetFilingReconciliationReport? = nil,
        options: AssetsOverviewOptions = .init()
    ) -> String {
        let css = StatementStyleCSS.base().render()

        let visibleGroups = overview.groups.filter { group in
            !shouldOmitAssetsOverviewGroup(
                group,
                options: options
            )
        }
        let omittedGroups = overview.groups.filter { group in
            shouldOmitAssetsOverviewGroup(
                group,
                options: options
            )
        }

        let visibleOpeningTotal = visibleGroups.reduce(Decimal(0)) {
            $0 + $1.totals.openingCarryingAmount
        }
        let visibleClosingTotal = visibleGroups.reduce(Decimal(0)) {
            $0 + $1.totals.closingCarryingAmount
        }

        let omittedOpeningTotal = omittedGroups.reduce(Decimal(0)) {
            $0 + $1.totals.openingCarryingAmount
        }
        let omittedClosingTotal = omittedGroups.reduce(Decimal(0)) {
            $0 + $1.totals.closingCarryingAmount
        }

        let diagnosticPairs = overview.diagnosticCounts
            .sorted { lhs, rhs in
                if lhs.value == rhs.value {
                    return lhs.key < rhs.key
                }

                return lhs.value > rhs.value
            }

        let doc: HTMLDocument = HTML.document {
            HTML.html(["lang": "nl"]) {
                HTML.head {
                    HTML.meta(.charset())
                    HTML.meta(.viewport())
                    HTML.title(options.title)
                    HTML.style(css)
                }

                HTML.body(["class": "sr-assets"]) {
                    HTML.h1 {
                        HTML.text(options.title)
                    }

                    if let subtitle = options.subtitle {
                        HTML.div(["class": "subtitle"]) {
                            HTML.text(subtitle)
                        }
                    }

                    HTML.div(["class": "summary"]) {
                        HTML.text("Period: \(overview.period.string())")
                    }
                    HTML.div(["class": "summary"]) {
                        HTML.text("Assets inspected: \(overview.summary.assetCount)")
                    }
                    HTML.div(["class": "summary"]) {
                        HTML.text("Flagged assets: \(overview.summary.flaggedAssetCount)")
                    }

                    if overview.summary.unclassifiedNonZeroAssetCount > 0 {
                        HTML.h2 {
                            HTML.text("Warning")
                        }

                        HTML.div(["class": "summary"]) {
                            HTML.text("Unclassified non-zero assets: \(overview.summary.unclassifiedNonZeroAssetCount)")
                        }
                        HTML.div(["class": "summary"]) {
                            HTML.text("Unclassified acquisition cost total: \(fmtAssetsOverviewAmount(overview.summary.unclassifiedNonZeroTotals.acquisitionCost, currencySymbol: options.currencySymbol))")
                        }
                        HTML.div(["class": "summary"]) {
                            HTML.text("Unclassified opening carrying amount total: \(fmtAssetsOverviewAmount(overview.summary.unclassifiedNonZeroTotals.openingCarryingAmount, currencySymbol: options.currencySymbol))")
                        }
                        HTML.div(["class": "summary"]) {
                            HTML.text("Unclassified investments in period: \(fmtAssetsOverviewAmount(overview.summary.unclassifiedNonZeroTotals.periodInvestment, currencySymbol: options.currencySymbol))")
                        }
                        HTML.div(["class": "summary"]) {
                            HTML.text("Unclassified depreciation in period: \(fmtAssetsOverviewAmount(overview.summary.unclassifiedNonZeroTotals.periodDepreciation, currencySymbol: options.currencySymbol))")
                        }
                        HTML.div(["class": "summary"]) {
                            HTML.text("Unclassified closing carrying amount total: \(fmtAssetsOverviewAmount(overview.summary.unclassifiedNonZeroTotals.closingCarryingAmount, currencySymbol: options.currencySymbol))")
                        }
                        HTML.div(["class": "summary"]) {
                            HTML.text("Unclassified residual amount total: \(fmtAssetsOverviewAmount(overview.summary.unclassifiedNonZeroTotals.residualAmount, currencySymbol: options.currencySymbol))")
                        }

                        for row in overview.summary.unclassifiedNonZeroRows {
                            HTML.div(["class": "summary"]) {
                                HTML.text("• \(row.displayName) (\(row.entityKey.identifier(displaying: .fullchain)))")
                            }
                        }
                    }

                    if options.showDiagnostics && !diagnosticPairs.isEmpty {
                        HTML.h2 {
                            HTML.text("Diagnostics")
                        }

                        for pair in diagnosticPairs {
                            HTML.div(["class": "summary"]) {
                                HTML.text("• \(pair.key): \(pair.value)")
                            }
                        }
                    }

                    if !omittedGroups.isEmpty {
                        HTML.h2 {
                            HTML.text("Weggelaten nul-secties")
                        }

                        HTML.div(["class": "summary"]) {
                            HTML.text("De volgende secties zijn standaard weggelaten omdat alle getoonde bedragen € 0,00 zijn: \(omittedGroups.map(\.name).joined(separator: ", ")).")
                        }
                        HTML.div(["class": "summary"]) {
                            HTML.text("Weggelaten boekwaarde begin boekjaar: \(fmtAssetsOverviewAmount(omittedOpeningTotal, currencySymbol: options.currencySymbol))")
                        }
                        HTML.div(["class": "summary"]) {
                            HTML.text("Weggelaten boekwaarde einde boekjaar: \(fmtAssetsOverviewAmount(omittedClosingTotal, currencySymbol: options.currencySymbol))")
                        }
                    }

                    for group in visibleGroups {
                        renderAssetsOverviewGroup(
                            group,
                            options: options
                        )
                    }

                    if !overview.groups.isEmpty {
                        HTML.h2 {
                            HTML.text("Totaal activa")
                        }

                        HTML.table(["class": "tbl tbl-assets-summary"]) {
                            HTML.thead {
                                HTML.tr {
                                    HTML.th(["class": "col-label"]) {
                                        HTML.text("Label")
                                    }
                                    HTML.th(["class": "col-money"]) {
                                        HTML.text("Bedrag")
                                    }
                                }
                            }
                            HTML.tbody {
                                HTML.tr {
                                    HTML.td(["class": "col-label cell-wrap"]) {
                                        HTML.span(["class": "cell-main"]) {
                                            HTML.text("Boekwaarde begin boekjaar")
                                        }
                                    }
                                    HTML.td(["class": "col-money"]) {
                                        HTML.strong {
                                            HTML.text(
                                                fmtAssetsOverviewAmount(
                                                    visibleOpeningTotal,
                                                    currencySymbol: options.currencySymbol
                                                )
                                            )
                                        }
                                    }
                                }

                                HTML.tr {
                                    HTML.td(["class": "col-label cell-wrap"]) {
                                        HTML.span(["class": "cell-main"]) {
                                            HTML.text("Boekwaarde einde boekjaar")
                                        }
                                    }
                                    HTML.td(["class": "col-money"]) {
                                        HTML.strong {
                                            HTML.text(
                                                fmtAssetsOverviewAmount(
                                                    visibleClosingTotal,
                                                    currencySymbol: options.currencySymbol
                                                )
                                            )
                                        }
                                    }
                                }
                            }
                        }
                    }

                    if
                        options.showReconciliation,
                        let reconciliation
                    {
                        renderAssetsReconciliationSection(
                            reconciliation,
                            currencySymbol: options.currencySymbol
                        )
                    }
                }
            }
        }

        return doc.render(
            default: HTMLDocument.RenderDefault.minified,
            doctype: true
        )
    }
}

extension StatementHTMLRenderer {
    @HTMLBuilder
    private static func renderAssetsOverviewGroup(
        _ group: AssetsOverviewGroup,
        options: AssetsOverviewOptions
    ) -> [any HTMLNode] {
        let profile = AssetsOverviewColumnProfile.forSection(group.section)
        let headerCells = profile.headers

        HTML.h2 {
            HTML.text(group.name)
        }

        HTML.table(["class": "tbl tbl-assets-overview"]) {
            HTML.thead {
                HTML.tr {
                    HTML.th(["class": "col-label"]) {
                        HTML.text("Post")
                    }

                    for header in headerCells {
                        HTML.th(["class": "col-money"]) {
                            HTML.text(header)
                        }
                    }
                }
            }

            HTML.tbody {
                for line in group.lines {
                    let lineCells = assetsOverviewCells(
                        for: line.totals,
                        profile: profile,
                        currencySymbol: options.currencySymbol
                    )

                    HTML.tr {
                        HTML.td(["class": "col-label cell-wrap"]) {
                            HTML.span(["class": "cell-main"]) {
                                HTML.text(line.name)
                            }
                        }

                        for value in lineCells {
                            HTML.td(["class": "col-money"]) {
                                HTML.text(value)
                            }
                        }
                    }

                    if options.showUnderlyingRows {
                        let filteredRows = line.rows.filter { row in
                            if options.showOnlyFlaggedUnderlyingRows && !row.hasIssues {
                                return false
                            }

                            if !options.showZeroUnderlyingRows && !hasVisibleAssetsOverviewAmounts(row) {
                                return false
                            }

                            return true
                        }

                        for row in filteredRows {
                            let rowAmounts = assetsOverviewAmounts(for: row)
                            let rowCells = assetsOverviewCells(
                                for: rowAmounts,
                                profile: profile,
                                currencySymbol: options.currencySymbol
                            )

                            HTML.tr {
                                HTML.td(["class": "col-label cell-wrap"]) {
                                    HTML.span(["class": "cell-main"]) {
                                        HTML.text(row.displayName)
                                    }

                                    HTML.span(["class": "cell-meta"]) {
                                        HTML.text(row.entityKey.identifier(displaying: .fullchain))
                                    }

                                    if let details = row.details, !details.isEmpty {
                                        HTML.span(["class": "cell-meta"]) {
                                            HTML.text(details)
                                        }
                                    }

                                    if row.hasIssues {
                                        HTML.span(["class": "cell-flags"]) {
                                            HTML.text(row.flags.joined(separator: " | "))
                                        }
                                    }
                                }

                                for value in rowCells {
                                    HTML.td(["class": "col-money"]) {
                                        HTML.text(value)
                                    }
                                }
                            }
                        }
                    }
                }

                let totalCells = assetsOverviewCells(
                    for: group.totals,
                    profile: profile,
                    currencySymbol: options.currencySymbol
                )

                HTML.tr {
                    HTML.td(["class": "col-label cell-wrap"]) {
                        HTML.strong {
                            HTML.span(["class": "cell-main"]) {
                                HTML.text(group.totalLabel)
                            }
                        }
                    }

                    for value in totalCells {
                        HTML.td(["class": "col-money"]) {
                            HTML.strong {
                                HTML.text(value)
                            }
                        }
                    }
                }
            }
        }
    }

    @HTMLBuilder
    private static func renderAssetsReconciliationSection(
        _ report: AssetFilingReconciliationReport,
        currencySymbol: String
    ) -> [any HTMLNode] {
        let sections = Array(
            Set(report.rows.map(\.section))
        ).sorted { lhs, rhs in
            lhs.sortOrder < rhs.sortOrder
        }

        HTML.h2 {
            HTML.text("Asset filing reconciliation")
        }

        HTML.div(["class": "summary"]) {
            HTML.text("Checks: \(report.checkCount)")
        }
        HTML.div(["class": "summary"]) {
            HTML.text("Failures: \(report.failureCount)")
        }
        HTML.div(["class": "summary"]) {
            HTML.text("Tolerance: \(fmtAssetsOverviewAmount(report.tolerance, currencySymbol: currencySymbol))")
        }

        if !report.uncheckedSections.isEmpty {
            HTML.div(["class": "summary"]) {
                HTML.text("Unchecked sections: \(report.uncheckedSections.map(\.label).joined(separator: ", "))")
            }
        }

        HTML.table(["class": "tbl"]) {
            HTML.thead {
                HTML.tr {
                    HTML.th {
                        HTML.text("Section")
                    }
                    HTML.th {
                        HTML.text("Metric")
                    }
                    HTML.th(["style": "text-align: right;"]) {
                        HTML.text("Projected")
                    }
                    HTML.th(["style": "text-align: right;"]) {
                        HTML.text("Ledger")
                    }
                    HTML.th(["style": "text-align: right;"]) {
                        HTML.text("Diff")
                    }
                    HTML.th {
                        HTML.text("Status")
                    }
                }
            }

            HTML.tbody {
                for section in sections {
                    let rows = report.rows.filter { $0.section == section }

                    for row in rows {
                        HTML.tr {
                            HTML.td {
                                HTML.text(section.label)
                            }
                            HTML.td {
                                HTML.div {
                                    HTML.text(row.metric.label)
                                }
                                HTML.div(["style": "font-size: 11px; color: #666;"]) {
                                    HTML.text(row.ledgerSelector)
                                }

                                if !row.matchedCodes.isEmpty {
                                    HTML.div(["style": "font-size: 11px; color: #666;"]) {
                                        HTML.text("Matched codes: \(row.matchedCodes.joined(separator: ", "))")
                                    }
                                }

                                if !row.notes.isEmpty {
                                    HTML.div(["style": "font-size: 11px; color: #666;"]) {
                                        HTML.text(row.notes.joined(separator: " | "))
                                    }
                                }
                            }
                            HTML.td(["style": "text-align: right; white-space: nowrap;"]) {
                                HTML.text(fmtAssetsOverviewAmount(row.projected, currencySymbol: currencySymbol))
                            }
                            HTML.td(["style": "text-align: right; white-space: nowrap;"]) {
                                HTML.text(fmtAssetsOverviewAmount(row.ledger, currencySymbol: currencySymbol))
                            }
                            HTML.td(["style": "text-align: right; white-space: nowrap;"]) {
                                HTML.text(fmtAssetsOverviewAmount(row.difference, currencySymbol: currencySymbol))
                            }
                            HTML.td {
                                HTML.text(row.passed ? "OK" : "FAIL")
                            }
                        }
                    }
                }
            }
        }
    }

    private static func assetsOverviewAmounts(
        for row: AssetsOverviewRow
    ) -> AssetsOverviewAmounts {
        AssetsOverviewAmounts(
            acquisitionCost: row.acquisitionCost ?? 0,
            openingCarryingAmount: row.openingCarryingAmount,
            periodInvestment: row.periodInvestment,
            periodDepreciation: row.periodDepreciation,
            closingCarryingAmount: row.closingCarryingAmount,
            residualAmount: row.residualAmount ?? 0
        )
    }

    private static func assetsOverviewCells(
        for amounts: AssetsOverviewAmounts,
        profile: AssetsOverviewColumnProfile,
        currencySymbol: String
    ) -> [String] {
        switch profile {
        case .intangibleFixedAssets, .tangibleFixedAssets:
            return [
                fmtAssetsOverviewAmount(amounts.acquisitionCost, currencySymbol: currencySymbol),
                fmtAssetsOverviewAmount(amounts.openingCarryingAmount, currencySymbol: currencySymbol),
                fmtAssetsOverviewAmount(amounts.closingCarryingAmount, currencySymbol: currencySymbol),
                fmtAssetsOverviewAmount(amounts.residualAmount, currencySymbol: currencySymbol),
            ]

        case .financialFixedAssets, .inventory, .securities, .liquidAssets:
            return [
                fmtAssetsOverviewAmount(amounts.openingCarryingAmount, currencySymbol: currencySymbol),
                fmtAssetsOverviewAmount(amounts.closingCarryingAmount, currencySymbol: currencySymbol),
            ]

        case .receivables:
            return [
                fmtAssetsOverviewAmount(amounts.acquisitionCost, currencySymbol: currencySymbol),
                fmtAssetsOverviewAmount(amounts.openingCarryingAmount, currencySymbol: currencySymbol),
                fmtAssetsOverviewAmount(amounts.closingCarryingAmount, currencySymbol: currencySymbol),
            ]

        case .unclassified:
            return [
                fmtAssetsOverviewAmount(amounts.acquisitionCost, currencySymbol: currencySymbol),
                fmtAssetsOverviewAmount(amounts.openingCarryingAmount, currencySymbol: currencySymbol),
                fmtAssetsOverviewAmount(amounts.closingCarryingAmount, currencySymbol: currencySymbol),
                fmtAssetsOverviewAmount(amounts.residualAmount, currencySymbol: currencySymbol),
            ]
        }
    }
}

@inline(__always)
private func shouldOmitAssetsOverviewGroup(
    _ group: AssetsOverviewGroup,
    options: StatementHTMLRenderer.AssetsOverviewOptions
) -> Bool {
    guard options.omitZeroOnlySupplementarySections else {
        return false
    }

    guard isSupplementaryAssetsOverviewSection(group.section) else {
        return false
    }

    return !hasVisibleAssetsOverviewAmounts(group.totals)
}

@inline(__always)
private func isSupplementaryAssetsOverviewSection(
    _ section: AssetsOverviewSection
) -> Bool {
    switch section {
    case .financialFixedAssets,
         .inventory,
         .receivables,
         .securities,
         .liquidAssets:
        return true

    case .intangibleFixedAssets,
         .tangibleFixedAssets,
         .unclassified:
        return false
    }
}

@inline(__always)
private func hasVisibleAssetsOverviewAmounts(
    _ amounts: AssetsOverviewAmounts
) -> Bool {
    if amounts.acquisitionCost != 0 { return true }
    if amounts.openingCarryingAmount != 0 { return true }
    if amounts.periodInvestment != 0 { return true }
    if amounts.periodDepreciation != 0 { return true }
    if amounts.closingCarryingAmount != 0 { return true }
    if amounts.residualAmount != 0 { return true }
    return false
}

@inline(__always)
private func hasVisibleAssetsOverviewAmounts(
    _ row: AssetsOverviewRow
) -> Bool {
    hasVisibleAssetsOverviewAmounts(
        AssetsOverviewAmounts(
            acquisitionCost: row.acquisitionCost ?? 0,
            openingCarryingAmount: row.openingCarryingAmount,
            periodInvestment: row.periodInvestment,
            periodDepreciation: row.periodDepreciation,
            closingCarryingAmount: row.closingCarryingAmount,
            residualAmount: row.residualAmount ?? 0
        )
    )
}

@inline(__always)
private func fmtAssetsOverviewAmount(
    _ value: Decimal,
    currencySymbol: String
) -> String {
    let formatter = NumberFormatter()
    formatter.locale = Locale(identifier: "nl_NL")
    formatter.numberStyle = .currency
    formatter.currencySymbol = currencySymbol
    formatter.minimumFractionDigits = 2
    formatter.maximumFractionDigits = 2

    return formatter.string(from: value as NSDecimalNumber)
        ?? value.description
}
