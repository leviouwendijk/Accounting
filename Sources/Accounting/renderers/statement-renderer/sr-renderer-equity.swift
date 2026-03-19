import Foundation
import HTML

public extension StatementHTMLRenderer {
    static func renderEquityOverviewHTML(
        title: String,
        history: [EquityPeriod],           // full history from inception
        chart: CompiledChart,
        entities: EntityStore,
        view: ClosedRange<Int>? = nil,     // which periods to show
        options: Options = .init()         // reuse StatementHTMLRenderer.Options
    ) throws -> String {
        let cfg = EquityRollforwardConfig()

        // 1) Build full history rollforward, then slice window.
        // let roll = try buildGlobalRollforward(
        let roll = try OwnerEquity.Rollforward.global_rollforward(
            history: history,
            chart: chart,
            entities: entities,
            cfg: cfg
        )

        let css = StatementStyleCSS.base().render()

        // If there is no rollforward, emit a minimal HTML doc.
        guard !roll.isEmpty else {
            let doc = HTML.document {
                HTML.html(["lang": "nl"]) {
                    HTML.head {
                        HTML.meta(.charset())
                        HTML.title(title)
                        HTML.style(css)
                    }
                    HTML.body(["class": "sr-eq"]) {
                        HTML.h1 {
                            HTML.text(escape(title))
                        }
                        if let sub = options.subtitle {
                            HTML.div(["class": "sr-eq-sub"]) {
                                HTML.text(escape(sub))
                            }
                        }
                        HTML.p {
                            HTML.text("Geen periodes.")
                        }
                    }
                }
            }
            return doc.render(default: .pretty, doctype: true)
        }

        // Windowing
        let lo0 = view?.lowerBound ?? 0
        let hi0 = view?.upperBound ?? (roll.count - 1)
        let lo  = max(0, min(lo0, roll.count - 1))
        let hi  = max(lo, min(hi0, roll.count - 1))
        let shown       = Array(roll[lo...hi])
        let shownLabels = Array(history[lo...hi].map { $0.label })

        let names = ownerNameMap(entities) // id -> display name

        @inline(__always)
        func fmt(_ x: Decimal) -> String {
            fmtDec(
                roundD(x, digits: cfg.fractionDigits),
                digits: cfg.fractionDigits
            )
        }

        struct EquityRowView {
            let name: String
            let begin: Decimal
            let stort: Decimal
            let onttrek: Decimal
            let winst: Decimal
            let end: Decimal
        }

        struct PeriodView {
            let label: String
            let winstSourceDescription: String
            let niTotal: Decimal
            let openingTotal: Decimal
            let closingTotal: Decimal

            let rows: [EquityRowView]
            let tBegin: Decimal
            let tStort: Decimal
            let tOnt: Decimal
            let tWinst: Decimal
            let tEnd: Decimal
        }

        func amountClass(_ x: Decimal) -> String {
            x < 0 ? "sr-eq-amount sr-eq-neg" : "sr-eq-amount"
        }

        // 2) Precompute pure view-model outside of any HTMLBuilder context
        let periodViews: [PeriodView] = shown.indices.map { idx in
            let period = shown[idx]
            let label  = shownLabels[idx]

            var rows: [EquityRowView] = []
            var tBegin: Decimal = 0
            var tStort: Decimal = 0
            var tOnt:   Decimal = 0
            var tWinst: Decimal = 0
            var tEnd:   Decimal = 0

            for oid in period.owners {
                let nm    = names[Int?(oid)] ?? "owner#\(oid)"
                let begin = period.beginByOwner[oid] ?? 0
                let dlt   = period.deltas[oid] ?? OwnerDelta(stort: 0, onttrek: 0, winst: 0)
                let end   = period.endByOwner[oid] ?? (begin + dlt.delta)

                tBegin += begin
                tStort += dlt.stort
                tOnt   += dlt.onttrek
                tWinst += dlt.winst
                tEnd   += end

                rows.append(
                    EquityRowView(
                        name: nm,
                        begin: begin,
                        stort: dlt.stort,
                        onttrek: dlt.onttrek,
                        winst: dlt.winst,
                        end: end
                    )
                )
            }

            return PeriodView(
                label: label,
                winstSourceDescription: period.winstSource.description,
                niTotal: period.niTotal,
                openingTotal: period.openingTotal,
                closingTotal: period.closingTotal,
                rows: rows,
                tBegin: tBegin,
                tStort: tStort,
                tOnt: tOnt,
                tWinst: tWinst,
                tEnd: tEnd
            )
        }

        // 3) Pure HTML DSL render using the precomputed view-model
        let doc = HTML.document {
            HTML.html(["lang": "nl"]) {
                HTML.head {
                    HTML.meta(.charset())
                    HTML.title(title)
                    HTML.style(css)
                }

                HTML.body(["class": "sr-eq"]) {
                    HTML.h1 {
                        HTML.text(escape(title))
                    }
                    if let sub = options.subtitle {
                        HTML.div(["class": "sr-eq-sub"]) {
                            HTML.text(escape(sub))
                        }
                    }

                    for periodView in periodViews {
                        HTML.div(["class": "sr-eq-period"]) {
                            HTML.h2 {
                                HTML.text(escape(periodView.label))
                            }

                            HTML.div(["class": "sr-eq-summary"]) {
                                HTML.text("Winst bron: \(escape(periodView.winstSourceDescription))")
                            }
                            HTML.div(["class": "sr-eq-summary"]) {
                                HTML.text("• Nettowinst (totaal, geïnjecteerd): \(fmt(periodView.niTotal))")
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
                                    for row in periodView.rows {
                                        HTML.tr {
                                            HTML.td(["class": "sr-eq-left"]) {
                                                HTML.text(escape(row.name))
                                            }
                                            HTML.td(["class": amountClass(row.begin)]) {
                                                HTML.text(fmt(row.begin))
                                            }
                                            HTML.td(["class": amountClass(row.stort)]) {
                                                HTML.text(fmt(row.stort))
                                            }
                                            HTML.td(["class": amountClass(row.onttrek)]) {
                                                HTML.text(fmt(row.onttrek))
                                            }
                                            HTML.td(["class": amountClass(row.winst)]) {
                                                HTML.text(fmt(row.winst))
                                            }
                                            HTML.td(["class": amountClass(row.end)]) {
                                                HTML.text(fmt(row.end))
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
                                            HTML.text(fmt(periodView.tBegin))
                                        }
                                        HTML.th {
                                            HTML.text(fmt(periodView.tStort))
                                        }
                                        HTML.th {
                                            HTML.text(fmt(periodView.tOnt))
                                        }
                                        HTML.th {
                                            HTML.text(fmt(periodView.tWinst))
                                        }
                                        HTML.th {
                                            HTML.text(fmt(periodView.tEnd))
                                        }
                                    }
                                }
                            }

                            HTML.div(["class": "sr-eq-summary"]) {
                                HTML.text(
                                    "Check totals → Opening: \(fmt(periodView.openingTotal)) | Closing: \(fmt(periodView.closingTotal))"
                                )
                            }
                            HTML.div(["class": "sr-eq-summary"]) {
                                HTML.text(
                                    "Identity: Begin + Stort − Onttrek + Winst = \(fmt(periodView.tEnd))"
                                )
                            }
                        }
                    }
                }
            }
        }

        return doc.render(default: .pretty, doctype: true)
    }
}
