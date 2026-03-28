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

fileprivate struct EquityHTMLOwnerRowView {
    let ownerName: String
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

fileprivate struct EquityHTMLPeriodView {
    let label: String
    let winstSourceDescription: String
    let niTotal: Decimal

    let ownerRows: [EquityHTMLOwnerRowView]

    let totalBegin: Decimal
    let totalStort: Decimal
    let totalOnttrek: Decimal
    let totalWinst: Decimal
    let totalEnd: Decimal

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
        options: EquityOptions = .init()
    ) throws -> String {
        let report = try EquityPresentation(
            reportTitle: title
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
            options: resolvedOptions
        )
    }

    @HTMLBuilder
    static func renderEquityOverviewBody(
        report: EquityRollforwardReport,
        entities: EntityStore,
        options: EquityOptions = .init()
    ) -> [any HTMLNode] {
        let cfg = EquityRollforwardConfig()
        let names = ownerNameMap(entities)
        let title = options.title.isEmpty ? report.title : options.title

        let diagnosticViews = buildEquityDiagnosticViews(
            report.diagnostics,
            names: names,
            cfg: cfg
        )

        let periodViews = buildEquityPeriodViews(
            report.periods,
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
                    for row in period.ownerRows {
                        HTML.tr {
                            HTML.td(["class": "sr-eq-left"]) {
                                HTML.text(row.ownerName)
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
                            HTML.text(fmtEquityAmount(period.totalBegin))
                        }
                        HTML.th {
                            HTML.text(fmtEquityAmount(period.totalStort))
                        }
                        HTML.th {
                            HTML.text(fmtEquityAmount(period.totalOnttrek))
                        }
                        HTML.th {
                            HTML.text(fmtEquityAmount(period.totalWinst))
                        }
                        HTML.th {
                            HTML.text(fmtEquityAmount(period.totalEnd))
                        }
                    }
                }
            }

            HTML.div(["class": "sr-eq-summary"]) {
                HTML.text(
                    "Check totals → Opening: \(fmtEquityAmount(period.openingTotal)) | Closing: \(fmtEquityAmount(period.closingTotal))"
                )
            }

            HTML.div(["class": "sr-eq-summary"]) {
                HTML.text(
                    "Identity: Begin + Stort − Onttrek + Winst = \(fmtEquityAmount(period.identityTotal))"
                )
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
                                HTML.text("%")
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

            if options.showUnassignedEquity, let unassigned = period.unassignedEquity {
                HTML.div(["class": "sr-eq-summary"]) {
                    HTML.text("· [debug] unassigned equity movements in \(period.label): \(fmtEquityAmount(unassigned))")
                }
            }

            if options.showDrawingsBreakdown, let drawings = period.drawings {
                HTML.div(["class": "sr-eq-summary"]) {
                    HTML.text("Onttrek – detail per post")
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
        names: [Int?: String],
        cfg: EquityRollforwardConfig
    ) -> [EquityHTMLPeriodView] {
        periods.map { period in
            let rows = period.rows

            var ownerRows: [EquityHTMLOwnerRowView] = []
            ownerRows.reserveCapacity(rows.owners.count)

            var totalBegin: Decimal = 0
            var totalStort: Decimal = 0
            var totalOnttrek: Decimal = 0
            var totalWinst: Decimal = 0
            var totalEnd: Decimal = 0

            for oid in rows.owners {
                let ownerName = names[Int?(oid)] ?? "owner#\(oid)"
                let begin = rows.beginByOwner[oid] ?? 0
                let delta = rows.deltas[oid] ?? OwnerDelta(
                    stort: 0,
                    onttrek: 0,
                    winst: 0
                )
                let end = rows.endByOwner[oid] ?? (begin + delta.delta)

                totalBegin += begin
                totalStort += delta.stort
                totalOnttrek += delta.onttrek
                totalWinst += delta.winst
                totalEnd += end

                ownerRows.append(
                    EquityHTMLOwnerRowView(
                        ownerName: ownerName,
                        begin: begin,
                        beginClass: equityAmountClass(begin),
                        stort: delta.stort,
                        stortClass: equityAmountClass(delta.stort),
                        onttrek: delta.onttrek,
                        onttrekClass: equityAmountClass(delta.onttrek),
                        winst: delta.winst,
                        winstClass: equityAmountClass(delta.winst),
                        end: end,
                        endClass: equityAmountClass(end)
                    )
                )
            }

            let allocationRows: [EquityHTMLAllocationRowView] = rows.owners.compactMap { oid in
                guard let note = rows.allocationNote[oid] else {
                    return nil
                }

                let ownerName = names[Int?(oid)] ?? "owner#\(oid)"

                return EquityHTMLAllocationRowView(
                    ownerName: ownerName,
                    percentText: fmtPct(note.percent, digits: cfg.fractionDigits),
                    amount: note.amount,
                    amountClass: equityAmountClass(note.amount)
                )
            }

            let drawings = buildEquityDrawingsView(
                period.drawings,
                names: names
            )

            return EquityHTMLPeriodView(
                label: period.label,
                winstSourceDescription: rows.winstSource.description,
                niTotal: rows.niTotal,
                ownerRows: ownerRows,
                totalBegin: totalBegin,
                totalStort: totalStort,
                totalOnttrek: totalOnttrek,
                totalWinst: totalWinst,
                totalEnd: totalEnd,
                openingTotal: rows.openingTotal,
                closingTotal: rows.closingTotal,
                identityTotal: totalBegin + totalStort - totalOnttrek + totalWinst,
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
            reconcilesText: "Check: Σ(posts) per owner equals Onttrek column → \(drawings.reconcilesWithOnttrek ? "OK" : "DIFF")",
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
