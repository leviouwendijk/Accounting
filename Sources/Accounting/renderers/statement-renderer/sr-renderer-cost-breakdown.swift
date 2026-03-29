import Foundation
import HTML
import CSS

public extension StatementHTMLRenderer {
    struct CostBreakdownOptions: Sendable {
        public var title: String
        public var subtitle: String?
        public var currencySymbol: String
        public var showMembers: Bool
        public var omitZeroMembers: Bool
        public var showReconciliation: Bool

        public init(
            title: String = "Overige bedrijfskosten",
            subtitle: String? = nil,
            currencySymbol: String = "€",
            showMembers: Bool = true,
            omitZeroMembers: Bool = true,
            showReconciliation: Bool = true
        ) {
            self.title = title
            self.subtitle = subtitle
            self.currencySymbol = currencySymbol
            self.showMembers = showMembers
            self.omitZeroMembers = omitZeroMembers
            self.showReconciliation = showReconciliation
        }
    }

    @HTMLBuilder
    static func renderCostBreakdownBody(
        report: CostBreakdownReport,
        options: CostBreakdownOptions = .init()
    ) -> [any HTMLNode] {
        HTML.h1 {
            HTML.text(options.title)
        }

        if let subtitle = options.subtitle {
            HTML.div(["class": "subtitle"]) {
                HTML.text(subtitle)
            }
        }

        HTML.table(["class": "tbl"]) {
            HTML.thead {
                HTML.tr {
                    HTML.th(["class": "col-label"]) {
                        HTML.text("Post")
                    }
                    HTML.th(["class": "col-money"]) {
                        HTML.text("Bedrag")
                    }
                }
            }

            HTML.tbody {
                for bucket in report.buckets {
                    HTML.tr {
                        HTML.td(["class": "col-label"]) {
                            HTML.text(bucket.label)
                        }
                        HTML.td(["class": "col-money"]) {
                            HTML.text(
                                fmtCostBreakdownAmount(
                                    bucket.amount,
                                    currencySymbol: options.currencySymbol
                                )
                            )
                        }
                    }
                }

                HTML.tr {
                    HTML.td(["class": "col-label"]) {
                        HTML.strong {
                            HTML.text("Totaal overige bedrijfskosten")
                        }
                    }
                    HTML.td(["class": "col-money"]) {
                        HTML.strong {
                            HTML.text(
                                fmtCostBreakdownAmount(
                                    report.total,
                                    currencySymbol: options.currencySymbol
                                )
                            )
                        }
                    }
                }
            }
        }

        if options.showMembers {
            for bucket in report.buckets {
                let visibleMembers = bucket.members.filter { member in
                    !options.omitZeroMembers || member.amount != 0
                }

                if !visibleMembers.isEmpty {
                    HTML.h2 {
                        HTML.text("\(bucket.label) – opbouw")
                    }

                    HTML.table(["class": "tbl"]) {
                        HTML.thead {
                            HTML.tr {
                                HTML.th(["class": "col-label"]) {
                                    HTML.text("Onderliggende groep")
                                }
                                HTML.th(["class": "col-money"]) {
                                    HTML.text("Bedrag")
                                }
                            }
                        }

                        HTML.tbody {
                            for member in visibleMembers {
                                HTML.tr {
                                    HTML.td(["class": "col-label"]) {
                                        HTML.text("\(member.label) [\(member.code)]")
                                    }
                                    HTML.td(["class": "col-money"]) {
                                        HTML.text(
                                            fmtCostBreakdownAmount(
                                                member.amount,
                                                currencySymbol: options.currencySymbol
                                            )
                                        )
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        if options.showReconciliation {
            let reconciliation = report.reconciliation

            HTML.h2 {
                HTML.text("Reconciliation")
            }

            HTML.table(["class": "tbl"]) {
                HTML.tbody {
                    reconciliationRow(
                        "Bronpost",
                        value: "\(reconciliation.sourceCode) (\(reconciliation.sourceLabel))"
                    )
                    reconciliationRow(
                        "Bron totaal",
                        amount: reconciliation.sourceTotal,
                        currencySymbol: options.currencySymbol
                    )
                    reconciliationRow(
                        "Som directe WBed-subgroepen",
                        amount: reconciliation.childRootTotal,
                        currencySymbol: options.currencySymbol
                    )
                    reconciliationRow(
                        "Verschil root vs directe subgroepen",
                        amount: reconciliation.childRootDifference,
                        currencySymbol: options.currencySymbol
                    )
                    reconciliationRow(
                        "Som filing buckets",
                        amount: reconciliation.bucketTotal,
                        currencySymbol: options.currencySymbol
                    )
                    reconciliationRow(
                        "Verschil root vs filing buckets",
                        amount: reconciliation.difference,
                        currencySymbol: options.currencySymbol
                    )
                    reconciliationRow(
                        "Andere kosten residual",
                        amount: reconciliation.otherResidual,
                        currencySymbol: options.currencySymbol
                    )
                    reconciliationRow(
                        "Som overige directe subgroepen",
                        amount: reconciliation.otherChildrenTotal,
                        currencySymbol: options.currencySymbol
                    )
                    reconciliationRow(
                        "Verschil residual vs overige subgroepen",
                        amount: reconciliation.otherDifference,
                        currencySymbol: options.currencySymbol
                    )
                    reconciliationRow(
                        "Tolerance",
                        amount: reconciliation.tolerance,
                        currencySymbol: options.currencySymbol
                    )
                    reconciliationRow(
                        "Status",
                        value: reconciliation.passed ? "ok" : "FAIL"
                    )
                }
            }
        }
    }

    static func renderCostBreakdownHTML(
        report: CostBreakdownReport,
        options: CostBreakdownOptions = .init()
    ) -> String {
        let css = CSSStyleSheet
            .merged([
                StatementStyleCSS.base(),
                StatementStyleCSS.costBreakdown()
            ])
            .render()

        let doc: HTMLDocument = HTML.document {
            HTML.html(["lang": "nl"]) {
                HTML.head {
                    HTML.meta(.charset())
                    HTML.meta(.viewport())
                    HTML.title(options.title)
                    HTML.style(css)
                }

                HTML.body(["class": "sr-cost-breakdown"]) {
                    renderCostBreakdownBody(
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

    @HTMLBuilder
    private static func reconciliationRow(
        _ label: String,
        amount: Decimal,
        currencySymbol: String
    ) -> [any HTMLNode] {
        HTML.tr {
            HTML.td(["class": "col-label"]) {
                HTML.text(label)
            }
            HTML.td(["class": "col-money"]) {
                HTML.text(
                    fmtCostBreakdownAmount(
                        amount,
                        currencySymbol: currencySymbol
                    )
                )
            }
        }
    }

    @HTMLBuilder
    private static func reconciliationRow(
        _ label: String,
        value: String
    ) -> [any HTMLNode] {
        HTML.tr {
            HTML.td(["class": "col-label"]) {
                HTML.text(label)
            }
            HTML.td(["class": "col-value"]) {
                HTML.text(value)
            }
        }
    }
}

private func fmtCostBreakdownAmount(
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
