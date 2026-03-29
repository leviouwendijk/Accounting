import Foundation
import HTML

extension StatementHTMLRenderer {
    public struct EquityOptions: Sendable {
        public var title: String
        public var subtitle: String?
        public var showAnchorMessages: Bool = true
        public var showDiagnostics: Bool = true
        public var showAllocation: Bool = true
        public var showDrawingsBreakdown: Bool = true
        public var showUnassignedEquity: Bool = true

        public init(
            title: String = "Equity rollforward (backsolved)",
            subtitle: String? = nil,
            showAnchorMessages: Bool = true,
            showDiagnostics: Bool = true,
            showAllocation: Bool = true,
            showDrawingsBreakdown: Bool = true,
            showUnassignedEquity: Bool = true
        ) {
            self.title = title
            self.subtitle = subtitle
            self.showAnchorMessages = showAnchorMessages
            self.showDiagnostics = showDiagnostics
            self.showAllocation = showAllocation
            self.showDrawingsBreakdown = showDrawingsBreakdown
            self.showUnassignedEquity = showUnassignedEquity
        }
    }
}

fileprivate struct EquityHTMLDiagnosticView {
    let header: String
    let payloadLines: [String]
}

struct EquityHTMLOwnerRowView: Sendable {
    let ownerName: String
    let detailText: String?
    let rowClass: String
    let exclusionBadgeText: String?

    let begin: Decimal
    let beginClass: String

    let stort: Decimal
    let stortClass: String

    let onttrek: Decimal
    let onttrekClass: String

    let winst: Decimal
    let winstClass: String

    let end: Decimal
    let endClass: String
}

fileprivate struct EquityHTMLAllocationRowView {
    let ownerName: String
    let percentText: String
    let amount: Decimal
    let amountClass: String
}

fileprivate struct EquityHTMLDrawingsRowView {
    let label: String
    let ownerAmounts: [Decimal]
    let ownerClasses: [String]
    let total: Decimal
    let totalClass: String
}

fileprivate struct EquityHTMLDrawingsView {
    let ownerNames: [String]
    let rows: [EquityHTMLDrawingsRowView]
    let ownerTotals: [Decimal]
    let grandTotal: Decimal
    let grandTotalClass: String
    let reconcilesText: String
    let auditLines: [String]
}

fileprivate struct EquityHTMLSectionView {
    let ownerRows: [EquityHTMLOwnerRowView]

    let totalBegin: Decimal
    let totalStort: Decimal
    let totalOnttrek: Decimal
    let totalWinst: Decimal
    let totalEnd: Decimal
}

fileprivate struct EquityHTMLPeriodView {
    let label: String
    let winstSourceDescription: String
    let niTotal: Decimal

    let ownerSections: [EquityHTMLSectionView]

    let actualTotalBegin: Decimal
    let actualTotalStort: Decimal
    let actualTotalOnttrek: Decimal
    let actualTotalWinst: Decimal
    let actualTotalEnd: Decimal

    let openingTotal: Decimal
    let closingTotal: Decimal
    let identityTotal: Decimal

    let allocationRows: [EquityHTMLAllocationRowView]
    let unassignedEquity: Decimal?
    let drawings: EquityHTMLDrawingsView?
}

public extension StatementHTMLRenderer {
    static func renderEquityOverviewHTML(
        title: String,
        history: [EquityPeriod],
        chart: CompiledChart,
        entities: EntityStore,
        view: ClosedRange<Int>? = nil,
        config cfg: EquityRollforwardConfig = .init(),
        options: EquityOptions = .init()
    ) throws -> String {
        let report = try EquityPresentation(
            reportTitle: title,
            config: cfg
        ).build(
            from: .init(
                chart: chart,
                history: history,
                entities: entities,
                view: view
            )
        )

        var resolvedOptions = options
        resolvedOptions.title = title

        return try renderEquityOverviewHTML(
            report: report,
            entities: entities,
            config: cfg,
            options: resolvedOptions
        )
    }

    @HTMLBuilder
    static func renderEquityOverviewBody(
        report: EquityRollforwardReport,
        entities: EntityStore,
        config cfg: EquityRollforwardConfig = .init(),
        options: EquityOptions = .init()
    ) -> [any HTMLNode] {
        let names = ownerNameMap(entities)
        let title = options.title.isEmpty ? report.title : options.title

        let diagnosticViews = buildEquityDiagnosticViews(
            report.diagnostics,
            names: names,
            cfg: cfg
        )

        let periodViews = buildEquityPeriodViews(
            report.periods,
            entities: entities,
            names: names,
            cfg: cfg
        )

        HTML.h1 {
            HTML.text(title)
        }

        if let subtitle = options.subtitle {
            HTML.div(["class": "sr-eq-sub"]) {
                HTML.text(subtitle)
            }
        }

        if periodViews.isEmpty {
            HTML.p {
                HTML.text("Geen periodes.")
            }
        } else {
            if options.showAnchorMessages {
                for message in report.anchorMessages {
                    HTML.div(["class": "sr-eq-summary"]) {
                        HTML.text(message)
                    }
                }
            }

            if options.showDiagnostics {
                for diagnostic in diagnosticViews {
                    HTML.div(["class": "sr-eq-summary"]) {
                        HTML.text(diagnostic.header)
                    }

                    for line in diagnostic.payloadLines {
                        HTML.div(["class": "sr-eq-summary"]) {
                            HTML.text(line)
                        }
                    }
                }
            }

            for period in periodViews {
                renderEquityPeriodSection(
                    period,
                    options: options
                )
            }
        }
    }

    static func renderEquityOverviewHTML(
        report: EquityRollforwardReport,
        entities: EntityStore,
        config cfg: EquityRollforwardConfig = .init(),
        options: EquityOptions = .init()
    ) throws -> String {
        let title = options.title.isEmpty ? report.title : options.title
        let css = StatementStyleCSS.base().render()

        let doc: HTMLDocument = HTML.document {
            HTML.html(["lang": "nl"]) {
                HTML.head {
                    HTML.meta(.charset())
                    HTML.meta(.viewport())
                    HTML.title(title)
                    HTML.style(css)
                }

                HTML.body(["class": "sr-eq"]) {
                    renderEquityOverviewBody(
                        report: report,
                        entities: entities,
                        config: cfg,
                        options: options
                    )
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
    private static func renderEquityPeriodSection(
        _ period: EquityHTMLPeriodView,
        options: EquityOptions
    ) -> [any HTMLNode] {
        HTML.div(["class": "sr-eq-period"]) {
            HTML.h2 {
                HTML.text(period.label)
            }

            HTML.div(["class": "sr-eq-summary"]) {
                HTML.text("Winst bron: \(period.winstSourceDescription)")
            }

            HTML.div(["class": "sr-eq-summary"]) {
                HTML.text("• Nettowinst (totaal, geïnjecteerd): \(fmtEquityAmount(period.niTotal))")
            }

            for section in period.ownerSections {
                HTML.table(["class": "sr-eq-table"]) {
                    HTML.thead {
                        HTML.tr {
                            HTML.th(["class": "sr-eq-left"]) {
                                HTML.text("Eigenaar")
                            }
                            HTML.th {
                                HTML.text("Beginvermogen")
                            }
                            HTML.th {
                                HTML.text("Stortingen")
                            }
                            HTML.th {
                                HTML.text("Onttrekkingen")
                            }
                            HTML.th {
                                HTML.text("Winstaandeel")
                            }
                            HTML.th {
                                HTML.text("Eindvermogen")
                            }
                        }
                    }

                    HTML.tbody {
                        for row in section.ownerRows {
                            HTML.tr(row.rowClass.isEmpty ? [:] : ["class": row.rowClass]) {
                                HTML.td(["class": "sr-eq-left"]) {
                                    HTML.div {
                                        HTML.text(row.ownerName)

                                        if let badge = row.exclusionBadgeText {
                                            HTML.span(["class": "sr-eq-row-badge"]) {
                                                HTML.text(" \(badge)")
                                            }
                                        }
                                    }

                                    if let detail = row.detailText, !detail.isEmpty {
                                        HTML.div(["class": "sr-eq-row-detail"]) {
                                            HTML.text(detail)
                                        }
                                    }
                                }

                                HTML.td(["class": row.beginClass]) {
                                    HTML.text(fmtEquityAmount(row.begin))
                                }

                                HTML.td(["class": row.stortClass]) {
                                    HTML.text(fmtEquityAmount(row.stort))
                                }

                                HTML.td(["class": row.onttrekClass]) {
                                    HTML.text(fmtEquityAmount(row.onttrek))
                                }

                                HTML.td(["class": row.winstClass]) {
                                    HTML.text(fmtEquityAmount(row.winst))
                                }

                                HTML.td(["class": row.endClass]) {
                                    HTML.text(fmtEquityAmount(row.end))
                                }
                            }
                        }
                    }

                    HTML.tfoot {
                        HTML.tr {
                            HTML.th(["class": "sr-eq-left"]) {
                                HTML.text("TOTAAL")
                            }

                            HTML.th {
                                HTML.text(fmtEquityAmount(section.totalBegin))
                            }

                            HTML.th {
                                HTML.text(fmtEquityAmount(section.totalStort))
                            }

                            HTML.th {
                                HTML.text(fmtEquityAmount(section.totalOnttrek))
                            }

                            HTML.th {
                                HTML.text(fmtEquityAmount(section.totalWinst))
                            }

                            HTML.th {
                                HTML.text(fmtEquityAmount(section.totalEnd))
                            }
                        }
                    }
                }
            }

            HTML.div(["class": "sr-eq-summary"]) {
                HTML.text(
                    "Werkelijk totaal (ruw) → " +
                    "Begin: \(fmtEquityAmount(period.actualTotalBegin)) | " +
                    "Stort: \(fmtEquityAmount(period.actualTotalStort)) | " +
                    "Onttrek: \(fmtEquityAmount(period.actualTotalOnttrek)) | " +
                    "Winst: \(fmtEquityAmount(period.actualTotalWinst)) | " +
                    "Eind: \(fmtEquityAmount(period.actualTotalEnd))"
                )
            }

            HTML.div(["class": "sr-eq-summary"]) {
                HTML.text("Check totals → Opening: \(fmtEquityAmount(period.openingTotal)) | Closing: \(fmtEquityAmount(period.closingTotal))")
            }

            HTML.div(["class": "sr-eq-summary"]) {
                HTML.text("Identity: Begin + Stort − Onttrekkingen + Winst = \(fmtEquityAmount(period.identityTotal))")
            }

            if options.showAllocation, !period.allocationRows.isEmpty {
                HTML.div(["class": "sr-eq-summary"]) {
                    HTML.text("NI allocation (used): \(period.winstSourceDescription)")
                }

                HTML.table(["class": "sr-eq-table"]) {
                    HTML.thead {
                        HTML.tr {
                            HTML.th(["class": "sr-eq-left"]) {
                                HTML.text("Eigenaar")
                            }
                            HTML.th {
                                HTML.text("Percentage")
                            }
                            HTML.th {
                                HTML.text("Bedrag")
                            }
                        }
                    }

                    HTML.tbody {
                        for row in period.allocationRows {
                            HTML.tr {
                                HTML.td(["class": "sr-eq-left"]) {
                                    HTML.text(row.ownerName)
                                }
                                HTML.td {
                                    HTML.text(row.percentText)
                                }
                                HTML.td(["class": row.amountClass]) {
                                    HTML.text(fmtEquityAmount(row.amount))
                                }
                            }
                        }
                    }
                }
            }

            if let unassigned = period.unassignedEquity, options.showUnassignedEquity {
                HTML.div(["class": "sr-eq-summary"]) {
                    HTML.text("Niet-toegewezen eigen vermogen mutaties: \(fmtEquityAmount(unassigned))")
                }
            }

            if options.showDrawingsBreakdown, let drawings = period.drawings {
                HTML.h3 {
                    HTML.text("Onttrekkingen uitsplitsing")
                }

                HTML.table(["class": "sr-eq-table"]) {
                    HTML.thead {
                        HTML.tr {
                            HTML.th(["class": "sr-eq-left"]) {
                                HTML.text("Post")
                            }

                            for ownerName in drawings.ownerNames {
                                HTML.th {
                                    HTML.text(ownerName)
                                }
                            }

                            HTML.th {
                                HTML.text("Totaal")
                            }
                        }
                    }

                    HTML.tbody {
                        for row in drawings.rows {
                            HTML.tr {
                                HTML.td(["class": "sr-eq-left"]) {
                                    HTML.text(row.label)
                                }

                                for idx in row.ownerAmounts.indices {
                                    HTML.td(["class": row.ownerClasses[idx]]) {
                                        HTML.text(fmtEquityAmount(row.ownerAmounts[idx]))
                                    }
                                }

                                HTML.td(["class": row.totalClass]) {
                                    HTML.text(fmtEquityAmount(row.total))
                                }
                            }
                        }
                    }

                    HTML.tfoot {
                        HTML.tr {
                            HTML.th(["class": "sr-eq-left"]) {
                                HTML.text("TOTAAL")
                            }

                            for amount in drawings.ownerTotals {
                                HTML.th {
                                    HTML.text(fmtEquityAmount(amount))
                                }
                            }

                            HTML.th {
                                HTML.text(fmtEquityAmount(drawings.grandTotal))
                            }
                        }
                    }
                }

                HTML.div(["class": "sr-eq-summary"]) {
                    HTML.text(drawings.reconcilesText)
                }

                if !drawings.auditLines.isEmpty {
                    HTML.div(["class": "sr-eq-summary"]) {
                        HTML.text("[Audit] Drawings codes under BEivKapPro* not matched by any group (signed totals):")
                    }

                    for line in drawings.auditLines {
                        HTML.div(["class": "sr-eq-summary"]) {
                            HTML.text(line)
                        }
                    }
                }
            }
        }
    }

    private static func buildEquityDiagnosticViews(
        _ diagnostics: [EquityDiagnostic],
        names: [Int?: String],
        cfg: EquityRollforwardConfig
    ) -> [EquityHTMLDiagnosticView] {
        diagnostics.map { diagnostic in
            let prefix = equityDiagnosticPrefix(diagnostic)
            let header: String

            if let periodLabel = diagnostic.periodLabel {
                header = "\(prefix) [\(periodLabel)] \(diagnostic.message)"
            } else {
                header = "\(prefix) \(diagnostic.message)"
            }

            let payloadLines: [String]
            switch diagnostic.payload {
            case .none:
                payloadLines = []

            case .ownerMap(let map):
                let total = map.values.reduce(0, +)

                var lines: [String] = [
                    "total = \(fmtDec(roundD(total, digits: cfg.fractionDigits), digits: cfg.fractionDigits))"
                ]

                for oid in map.keys.sorted() {
                    let ownerName = names[Int?(oid)] ?? "owner#\(oid)"
                    let amount = map[oid] ?? 0
                    let formatted = fmtDec(
                        roundD(amount, digits: cfg.fractionDigits),
                        digits: cfg.fractionDigits
                    )
                    lines.append("- \(ownerName): \(formatted)")
                }

                payloadLines = lines
            }

            return EquityHTMLDiagnosticView(
                header: header,
                payloadLines: payloadLines
            )
        }
    }

    private static func buildEquityPeriodViews(
        _ periods: [EquityReportPeriod],
        entities: EntityStore,
        names: [Int?: String],
        cfg: EquityRollforwardConfig
    ) -> [EquityHTMLPeriodView] {
        periods.map { period in
            let rows = period.rows

            let table = try? makeEquityOwnerDisplayTable(
                rows: rows,
                entities: entities,
                cfg: cfg
            )

            let ownerSections: [EquityHTMLSectionView] = (table?.sections ?? []).map { section in
                let ownerRows: [EquityHTMLOwnerRowView] = section.rows.map { row in
                    let rowClass = [
                        row.style == .subtotal ? "sr-eq-subtotal" : nil,
                        row.includeInSum ? nil : "sr-eq-excluded"
                    ]
                    .compactMap { $0 }
                    .joined(separator: " ")

                    let detailText = [
                        row.detail,
                        row.includeInSum ? nil : "Excluded from section total"
                    ]
                    .compactMap { value -> String? in
                        guard let value, !value.isEmpty else {
                            return nil
                        }

                        return value
                    }
                    .joined(separator: " • ")

                    return EquityHTMLOwnerRowView(
                        ownerName: row.label,
                        detailText: detailText.isEmpty ? nil : detailText,
                        rowClass: rowClass,
                        exclusionBadgeText: row.includeInSum ? nil : "excluded",
                        begin: row.begin,
                        beginClass: equityAmountClass(row.begin),
                        stort: row.stort,
                        stortClass: equityAmountClass(row.stort),
                        onttrek: row.onttrek,
                        onttrekClass: equityAmountClass(row.onttrek),
                        winst: row.winst,
                        winstClass: equityAmountClass(row.winst),
                        end: row.end,
                        endClass: equityAmountClass(row.end)
                    )
                }

                return EquityHTMLSectionView(
                    ownerRows: ownerRows,
                    totalBegin: section.totalBegin,
                    totalStort: section.totalStort,
                    totalOnttrek: section.totalOnttrek,
                    totalWinst: section.totalWinst,
                    totalEnd: section.totalEnd
                )
            }

            let allocationRows: [EquityHTMLAllocationRowView] = rows.owners.compactMap { oid in
                guard let note = rows.allocationNote[oid] else {
                    return nil
                }

                let ownerName = names[Int?(oid)] ?? "owner#\(oid)"

                return EquityHTMLAllocationRowView(
                    ownerName: ownerName,
                    percentText: fmtPct(
                        note.percent,
                        digits: cfg.fractionDigits
                    ),
                    amount: note.amount,
                    amountClass: equityAmountClass(note.amount)
                )
            }

            let drawings = buildEquityDrawingsView(
                period.drawings,
                names: names
            )

            let actualTotalBegin = table?.actualTotalBegin ?? 0
            let actualTotalStort = table?.actualTotalStort ?? 0
            let actualTotalOnttrek = table?.actualTotalOnttrek ?? 0
            let actualTotalWinst = table?.actualTotalWinst ?? 0
            let actualTotalEnd = table?.actualTotalEnd ?? 0

            return EquityHTMLPeriodView(
                label: period.label,
                winstSourceDescription: rows.winstSource.description,
                niTotal: rows.niTotal,
                ownerSections: ownerSections,
                actualTotalBegin: actualTotalBegin,
                actualTotalStort: actualTotalStort,
                actualTotalOnttrek: actualTotalOnttrek,
                actualTotalWinst: actualTotalWinst,
                actualTotalEnd: actualTotalEnd,
                openingTotal: rows.openingTotal,
                closingTotal: rows.closingTotal,
                identityTotal: actualTotalBegin + actualTotalStort - actualTotalOnttrek + actualTotalWinst,
                allocationRows: allocationRows,
                unassignedEquity: period.unassignedEquity,
                drawings: drawings
            )
        }
    }

    private static func buildEquityDrawingsView(
        _ drawings: EquityDrawingsBreakdownReport?,
        names: [Int?: String]
    ) -> EquityHTMLDrawingsView? {
        guard let drawings else {
            return nil
        }

        let ownerNames = drawings.owners.map { oid in
            names[Int?(oid)] ?? "owner#\(oid)"
        }

        let rowViews: [EquityHTMLDrawingsRowView] = drawings.rows.map { row in
            let ownerAmounts = drawings.owners.map { oid in
                row.amountsByOwner[oid] ?? 0
            }

            let ownerClasses = ownerAmounts.map(equityAmountClass)

            return EquityHTMLDrawingsRowView(
                label: row.label,
                ownerAmounts: ownerAmounts,
                ownerClasses: ownerClasses,
                total: row.total,
                totalClass: equityAmountClass(row.total)
            )
        }

        let ownerTotals = drawings.owners.map { oid in
            drawings.totalsByOwner[oid] ?? 0
        }

        let auditLines = drawings.uncapturedAudit
            .keys
            .sorted()
            .map { key in
                let value = drawings.uncapturedAudit[key] ?? 0
                return "• \(key): \(fmtEquityAmount(value))"
            }

        return EquityHTMLDrawingsView(
            ownerNames: ownerNames,
            rows: rowViews,
            ownerTotals: ownerTotals,
            grandTotal: drawings.grandTotal,
            grandTotalClass: equityAmountClass(drawings.grandTotal),
            reconcilesText: "Check: Σ(posts) per owner equals Onttrekkingen column → \(drawings.reconcilesWithOnttrek ? "OK" : "DIFF")",
            auditLines: auditLines
        )
    }

    private static func equityDiagnosticPrefix(
        _ diagnostic: EquityDiagnostic
    ) -> String {
        switch diagnostic.kind {
        case .info:
            return "[INFO]"
        case .warning:
            return "[WARNING]"
        case .assertion:
            return "[ASSERT]"
        }
    }

    private static func equityAmountClass(
        _ value: Decimal
    ) -> String {
        value < 0 ? "sr-eq-amount sr-eq-neg" : "sr-eq-amount"
    }

    private static func fmtEquityAmount(
        _ value: Decimal,
        digits: Int = 2
    ) -> String {
        fmtDec(
            roundD(value, digits: digits),
            digits: digits
        )
    }
}
