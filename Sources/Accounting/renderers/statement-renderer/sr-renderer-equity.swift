import Foundation
import HTML

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

    static func renderEquityOverviewHTML(
        report: EquityRollforwardReport,
        entities: EntityStore,
        options: EquityOptions = .init()
    ) throws -> String {
        let cfg = EquityRollforwardConfig()
        let css = StatementStyleCSS.base().render()
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

        if periodViews.isEmpty {
            let doc: HTMLDocument = HTML.document {
                HTML.html(["lang": "nl"]) {
                    HTML.head {
                        HTML.meta(.charset())
                        HTML.meta(.viewport())
                        HTML.title(title)
                        HTML.style(css)
                    }

                    HTML.body(["class": "sr-eq"]) {
                        HTML.h1 {
                            HTML.text(title)
                        }

                        if let subtitle = options.subtitle {
                            HTML.div(["class": "sr-eq-sub"]) {
                                HTML.text(subtitle)
                            }
                        }

                        HTML.p {
                            HTML.text("Geen periodes.")
                        }
                    }
                }
            }

            return doc.render(
                default: HTMLDocument.RenderDefault.minified,
                doctype: true
            )
        }

        let doc: HTMLDocument = HTML.document {
            HTML.html(["lang": "nl"]) {
                HTML.head {
                    HTML.meta(.charset())
                    HTML.meta(.viewport())
                    HTML.title(title)
                    HTML.style(css)
                }

                HTML.body(["class": "sr-eq"]) {
                    HTML.h1 {
                        HTML.text(title)
                    }

                    if let subtitle = options.subtitle {
                        HTML.div(["class": "sr-eq-sub"]) {
                            HTML.text(subtitle)
                        }
                    }

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

// public extension StatementHTMLRenderer {
//     static func renderEquityOverviewHTML(
//         title: String,
//         history: [EquityPeriod],           // full history from inception
//         chart: CompiledChart,
//         entities: EntityStore,
//         view: ClosedRange<Int>? = nil,     // which periods to show
//         options: Options = .init()         // reuse StatementHTMLRenderer.Options
//     ) throws -> String {
//         let cfg = EquityRollforwardConfig()

//         // 1) Build full history rollforward, then slice window.
//         // let roll = try buildGlobalRollforward(
//         let roll = try OwnerEquity.Rollforward.global_rollforward(
//             history: history,
//             chart: chart,
//             entities: entities,
//             cfg: cfg
//         )

//         let css = StatementStyleCSS.base().render()

//         // If there is no rollforward, emit a minimal HTML doc.
//         guard !roll.isEmpty else {
//             let doc = HTML.document {
//                 HTML.html(["lang": "nl"]) {
//                     HTML.head {
//                         HTML.meta(.charset())
//                         HTML.title(title)
//                         HTML.style(css)
//                     }
//                     HTML.body(["class": "sr-eq"]) {
//                         HTML.h1 {
//                             HTML.text(title)
//                         }
//                         if let sub = options.subtitle {
//                             HTML.div(["class": "sr-eq-sub"]) {
//                                 HTML.text(sub)
//                             }
//                         }
//                         HTML.p {
//                             HTML.text("Geen periodes.")
//                         }
//                     }
//                 }
//             }
//             return doc.render(default: .pretty, doctype: true)
//         }

//         // Windowing
//         let lo0 = view?.lowerBound ?? 0
//         let hi0 = view?.upperBound ?? (roll.count - 1)
//         let lo  = max(0, min(lo0, roll.count - 1))
//         let hi  = max(lo, min(hi0, roll.count - 1))
//         let shown       = Array(roll[lo...hi])
//         let shownLabels = Array(history[lo...hi].map { $0.label })

//         let names = ownerNameMap(entities) // id -> display name

//         @inline(__always)
//         func fmt(_ x: Decimal) -> String {
//             fmtDec(
//                 roundD(x, digits: cfg.fractionDigits),
//                 digits: cfg.fractionDigits
//             )
//         }

//         struct EquityRowView {
//             let name: String
//             let begin: Decimal
//             let stort: Decimal
//             let onttrek: Decimal
//             let winst: Decimal
//             let end: Decimal
//         }

//         struct PeriodView {
//             let label: String
//             let winstSourceDescription: String
//             let niTotal: Decimal
//             let openingTotal: Decimal
//             let closingTotal: Decimal

//             let rows: [EquityRowView]
//             let tBegin: Decimal
//             let tStort: Decimal
//             let tOnt: Decimal
//             let tWinst: Decimal
//             let tEnd: Decimal
//         }

//         func amountClass(_ x: Decimal) -> String {
//             x < 0 ? "sr-eq-amount sr-eq-neg" : "sr-eq-amount"
//         }

//         // 2) Precompute pure view-model outside of any HTMLBuilder context
//         let periodViews: [PeriodView] = shown.indices.map { idx in
//             let period = shown[idx]
//             let label  = shownLabels[idx]

//             var rows: [EquityRowView] = []
//             var tBegin: Decimal = 0
//             var tStort: Decimal = 0
//             var tOnt:   Decimal = 0
//             var tWinst: Decimal = 0
//             var tEnd:   Decimal = 0

//             for oid in period.owners {
//                 let nm    = names[Int?(oid)] ?? "owner#\(oid)"
//                 let begin = period.beginByOwner[oid] ?? 0
//                 let dlt   = period.deltas[oid] ?? OwnerDelta(stort: 0, onttrek: 0, winst: 0)
//                 let end   = period.endByOwner[oid] ?? (begin + dlt.delta)

//                 tBegin += begin
//                 tStort += dlt.stort
//                 tOnt   += dlt.onttrek
//                 tWinst += dlt.winst
//                 tEnd   += end

//                 rows.append(
//                     EquityRowView(
//                         name: nm,
//                         begin: begin,
//                         stort: dlt.stort,
//                         onttrek: dlt.onttrek,
//                         winst: dlt.winst,
//                         end: end
//                     )
//                 )
//             }

//             return PeriodView(
//                 label: label,
//                 winstSourceDescription: period.winstSource.description,
//                 niTotal: period.niTotal,
//                 openingTotal: period.openingTotal,
//                 closingTotal: period.closingTotal,
//                 rows: rows,
//                 tBegin: tBegin,
//                 tStort: tStort,
//                 tOnt: tOnt,
//                 tWinst: tWinst,
//                 tEnd: tEnd
//             )
//         }

//         // 3) Pure HTML DSL render using the precomputed view-model
//         let doc = HTML.document {
//             HTML.html(["lang": "nl"]) {
//                 HTML.head {
//                     HTML.meta(.charset())
//                     HTML.title(title)
//                     HTML.style(css)
//                 }

//                 HTML.body(["class": "sr-eq"]) {
//                     HTML.h1 {
//                         HTML.text((title))
//                     }
//                     if let sub = options.subtitle {
//                         HTML.div(["class": "sr-eq-sub"]) {
//                             HTML.text((sub))
//                         }
//                     }

//                     for periodView in periodViews {
//                         HTML.div(["class": "sr-eq-period"]) {
//                             HTML.h2 {
//                                 HTML.text((periodView.label))
//                             }

//                             HTML.div(["class": "sr-eq-summary"]) {
//                                 HTML.text("Winst bron: \((periodView.winstSourceDescription))")
//                             }
//                             HTML.div(["class": "sr-eq-summary"]) {
//                                 HTML.text("• Nettowinst (totaal, geïnjecteerd): \(fmt(periodView.niTotal))")
//                             }

//                             HTML.table(["class": "sr-eq-table"]) {
//                                 HTML.thead {
//                                     HTML.tr {
//                                         HTML.th(["class": "sr-eq-left"]) {
//                                             HTML.text("Eigenaar")
//                                         }
//                                         HTML.th {
//                                             HTML.text("Beginvermogen")
//                                         }
//                                         HTML.th {
//                                             HTML.text("Stortingen")
//                                         }
//                                         HTML.th {
//                                             HTML.text("Onttrekkingen")
//                                         }
//                                         HTML.th {
//                                             HTML.text("Winstaandeel")
//                                         }
//                                         HTML.th {
//                                             HTML.text("Eindvermogen")
//                                         }
//                                     }
//                                 }
//                                 HTML.tbody {
//                                     for row in periodView.rows {
//                                         HTML.tr {
//                                             HTML.td(["class": "sr-eq-left"]) {
//                                                 HTML.text((row.name))
//                                             }
//                                             HTML.td(["class": amountClass(row.begin)]) {
//                                                 HTML.text(fmt(row.begin))
//                                             }
//                                             HTML.td(["class": amountClass(row.stort)]) {
//                                                 HTML.text(fmt(row.stort))
//                                             }
//                                             HTML.td(["class": amountClass(row.onttrek)]) {
//                                                 HTML.text(fmt(row.onttrek))
//                                             }
//                                             HTML.td(["class": amountClass(row.winst)]) {
//                                                 HTML.text(fmt(row.winst))
//                                             }
//                                             HTML.td(["class": amountClass(row.end)]) {
//                                                 HTML.text(fmt(row.end))
//                                             }
//                                         }
//                                     }
//                                 }
//                                 HTML.tfoot {
//                                     HTML.tr {
//                                         HTML.th(["class": "sr-eq-left"]) {
//                                             HTML.text("TOTAAL")
//                                         }
//                                         HTML.th {
//                                             HTML.text(fmt(periodView.tBegin))
//                                         }
//                                         HTML.th {
//                                             HTML.text(fmt(periodView.tStort))
//                                         }
//                                         HTML.th {
//                                             HTML.text(fmt(periodView.tOnt))
//                                         }
//                                         HTML.th {
//                                             HTML.text(fmt(periodView.tWinst))
//                                         }
//                                         HTML.th {
//                                             HTML.text(fmt(periodView.tEnd))
//                                         }
//                                     }
//                                 }
//                             }

//                             HTML.div(["class": "sr-eq-summary"]) {
//                                 HTML.text(
//                                     "Check totals → Opening: \(fmt(periodView.openingTotal)) | Closing: \(fmt(periodView.closingTotal))"
//                                 )
//                             }
//                             HTML.div(["class": "sr-eq-summary"]) {
//                                 HTML.text(
//                                     "Identity: Begin + Stort − Onttrek + Winst = \(fmt(periodView.tEnd))"
//                                 )
//                             }
//                         }
//                     }
//                 }
//             }
//         }

//         return doc.render(default: .pretty, doctype: true)
//     }
// }
