import Foundation
import HTML

public extension StatementHTMLRenderer {
    struct AssetsSharesOptions: Sendable {
        public var title: String
        public var subtitle: String?
        public var currencySymbol: String

        public init(
            title: String = "Aandelen in activa",
            subtitle: String? = nil,
            currencySymbol: String = "€"
        ) {
            self.title = title
            self.subtitle = subtitle
            self.currencySymbol = currencySymbol
        }
    }

    @HTMLBuilder
    static func renderAssetsSharesBody(
        report: AssetSharesHistoryReport,
        options: AssetsSharesOptions = .init()
    ) -> [any HTMLNode] {
        HTML.h1 {
            HTML.text(options.title)
        }

        if let subtitle = options.subtitle {
            HTML.div(["class": "subtitle"]) {
                HTML.text(subtitle)
            }
        }

        if report.periods.isEmpty {
            HTML.div(["class": "summary"]) {
                HTML.text("(no periods)")
            }
        } else {
            for (index, period) in report.periods.enumerated() {
                if index > 0 {
                    HTML.div(["class": "sr-print-page-break-before"]) {}
                }

                HTML.h2 {
                    HTML.text(period.period.string())
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
                                    HTML.text("Som activa-aandelen begin boekjaar")
                                }
                            }
                            HTML.td(["class": "col-money"]) {
                                HTML.strong {
                                    HTML.text(
                                        fmtAssetsSharesAmount(
                                            period.openingCarryingAmount,
                                            currencySymbol: options.currencySymbol
                                        )
                                    )
                                }
                            }
                        }

                        HTML.tr(["class": "assets-share-detail-row"]) {
                            HTML.td([
                                "class": "col-label cell-wrap assets-share-detail-cell",
                                "colspan": "2"
                            ]) {
                                renderAssetsSharesBreakdownTable(
                                    period.breakdown,
                                    value: \.openingCarryingAmount,
                                    currencySymbol: options.currencySymbol
                                )
                            }
                        }

                        HTML.tr {
                            HTML.td(["class": "col-label cell-wrap"]) {
                                HTML.span(["class": "cell-main"]) {
                                    HTML.text("Som activa-aandelen investeringen in periode")
                                }
                            }
                            HTML.td(["class": "col-money"]) {
                                HTML.strong {
                                    HTML.text(
                                        fmtAssetsSharesAmount(
                                            period.periodInvestment,
                                            currencySymbol: options.currencySymbol
                                        )
                                    )
                                }
                            }
                        }

                        HTML.tr(["class": "assets-share-detail-row"]) {
                            HTML.td([
                                "class": "col-label cell-wrap assets-share-detail-cell",
                                "colspan": "2"
                            ]) {
                                renderAssetsSharesBreakdownTable(
                                    period.breakdown,
                                    value: \.periodInvestment,
                                    currencySymbol: options.currencySymbol
                                )
                            }
                        }

                        HTML.tr {
                            HTML.td(["class": "col-label cell-wrap"]) {
                                HTML.span(["class": "cell-main"]) {
                                    HTML.text("Som activa-aandelen einde boekjaar")
                                }
                            }
                            HTML.td(["class": "col-money"]) {
                                HTML.strong {
                                    HTML.text(
                                        fmtAssetsSharesAmount(
                                            period.closingCarryingAmount,
                                            currencySymbol: options.currencySymbol
                                        )
                                    )
                                }
                            }
                        }

                        HTML.tr(["class": "assets-share-detail-row"]) {
                            HTML.td([
                                "class": "col-label cell-wrap assets-share-detail-cell",
                                "colspan": "2"
                            ]) {
                                renderAssetsSharesBreakdownTable(
                                    period.breakdown,
                                    value: \.closingCarryingAmount,
                                    currencySymbol: options.currencySymbol
                                )
                            }
                        }
                    }
                }
            }
        }
    }

    static func renderAssetsSharesHTML(
        report: AssetSharesHistoryReport,
        options: AssetsSharesOptions = .init()
    ) -> String {
        let css = StatementStyleCSS.base().render()

        let doc: HTMLDocument = HTML.document {
            HTML.html(["lang": "nl"]) {
                HTML.head {
                    HTML.meta(.charset())
                    HTML.meta(.viewport())
                    HTML.title(options.title)
                    HTML.style(css)
                }

                HTML.body(["class": "sr-assets"]) {
                    renderAssetsSharesBody(
                        report: report,
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
    private static func renderAssetsSharesBreakdownTable(
        _ breakdown: [AssetsOverviewOwnerShareAmounts],
        value: KeyPath<AssetsOverviewOwnerShareAmounts, Decimal>,
        currencySymbol: String
    ) -> any HTMLNode {
        if breakdown.isEmpty {
            return HTML.span(["class": "cell-meta"]) {
                HTML.text("none")
            }
        }

        return HTML.table(["class": "assets-share-table"]) {
            HTML.tbody {
                for item in breakdown {
                    HTML.tr {
                        HTML.td(["class": "assets-share-label"]) {
                            HTML.text(item.ownerLabel)
                        }

                        HTML.td(["class": "assets-share-amount"]) {
                            HTML.text(
                                fmtAssetsSharesAmount(
                                    item[keyPath: value],
                                    currencySymbol: currencySymbol
                                )
                            )
                        }
                    }
                }
            }
        }
    }
}

@inline(__always)
private func fmtAssetsSharesAmount(
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
