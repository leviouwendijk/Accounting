import Foundation
import HTML
// import Constructors

public extension StatementHTMLRenderer {
    static func renderVATOverviewHTML(
        bundle: StatementBundle,
        chart: CompiledChart,
        options: Options = .init(title: "BTW / Taxes Overview"),
        includeCorrections: Bool = true,
        minAbs: Decimal = 0
    ) throws -> String {
        let overview = try RGSAssembler.vatOverview(
            options.title,
            bundle: bundle,
            chart: chart,
            includeCorrections: includeCorrections,
            minAbs: minAbs
        )
        return renderVATOverviewHTML(overview, options: options)
    }

    static func renderVATOverviewHTML(
        _ overview: VATOverview,
        options: Options = .init(title: "BTW / Taxes Overview")
    ) -> String {
        func fmt(_ x: Decimal) -> String {
            let nf = NumberFormatter()
            nf.locale = Locale(identifier: "nl_NL")
            nf.numberStyle = .currency
            nf.currencySymbol = options.currencySymbol
            nf.minimumFractionDigits = 2
            nf.maximumFractionDigits = 2
            return nf.string(from: x as NSDecimalNumber) ?? x.description
        }

        let css = StatementStyleCSS.base().render()

        func amountClass(_ x: Decimal) -> String {
            x < 0 ? "sr-vat-amount sr-vat-neg" : "sr-vat-amount"
        }

        let doc = HTML.document {
            HTML.html(["lang": "nl"]) {
                HTML.head {
                    HTML.meta(.charset())
                    HTML.meta(.viewport())
                    HTML.title(overview.title)
                    HTML.style(css)
                }
                HTML.body(["class": "sr-vat"]) {
                    HTML.h1 {
                        HTML.text(overview.title)
                    }
                    if let sub = options.subtitle {
                        HTML.div(["class": "sr-vat-sub"]) {
                            HTML.text(sub)
                        }
                    }

                    // Sections
                    for section in overview.sections {
                        HTML.h2 {
                            HTML.text(section.title)
                        }

                        HTML.table(["class": "sr-vat-table"]) {
                            HTML.thead {
                                HTML.tr {
                                    HTML.th {
                                        HTML.text("Label")
                                    }
                                    HTML.th {
                                        HTML.text("Code")
                                    }
                                    HTML.th(["class": "sr-vat-amount"]) {
                                        HTML.text("Bedrag")
                                    }
                                }
                            }
                            HTML.tbody {
                                let base = section.rows.map { $0.level }.min() ?? 0
                                for r in section.rows {
                                    let lvl = max(0, r.level - base)
                                    let indent = "padding-left: calc(16px * \(lvl));"
                                    let cls = amountClass(r.amount)

                                    HTML.tr {
                                        HTML.td(["class": "sr-vat-label"]) {
                                            HTML.div(["style": indent]) {
                                                HTML.text(r.label)
                                            }
                                        }
                                        HTML.td(["class": "sr-vat-code"]) {
                                            HTML.text(r.code)
                                        }
                                        HTML.td(["class": cls]) {
                                            HTML.text(fmt(r.amount))
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Summaries (including net position)
                    if !overview.summaries.isEmpty || overview.netPosition != nil {
                        HTML.div(["class": "sr-vat-summary"]) {
                            HTML.h2 {
                                HTML.text("Samenvatting")
                            }
                            HTML.table(["class": "sr-vat-table"]) {
                                HTML.tbody {
                                    for s in overview.summaries {
                                        let cls = amountClass(s.amount)
                                        let code = s.code ?? "—"

                                        HTML.tr {
                                            HTML.td(["class": "sr-vat-label"]) {
                                                HTML.text(s.label)
                                            }
                                            HTML.td(["class": "sr-vat-code"]) {
                                                HTML.text(code)
                                            }
                                            HTML.td(["class": cls]) {
                                                HTML.text(fmt(s.amount))
                                            }
                                        }
                                    }

                                    if let net = overview.netPosition {
                                        let cls = amountClass(net)
                                        HTML.tr {
                                            HTML.td(["class": "sr-vat-label"]) {
                                                HTML.strong {
                                                    HTML.text("Netto BTW-positie (te betalen − te vorderen)")
                                                }
                                            }
                                            HTML.td(["class": "sr-vat-code"]) {
                                                HTML.text("—")
                                            }
                                            HTML.td(["class": cls]) {
                                                HTML.strong {
                                                    HTML.text(fmt(net))
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        return doc.render(default: .pretty, doctype: true)
    }
}
