import Foundation
import HTML
import CSS

public extension StatementHTMLRenderer {
    struct VATStatusOptions: Sendable {
        public var title: String
        public var subtitle: String?
        public var currencySymbol: String
        public var showEntries: Bool
        public var showOnlyFlagged: Bool

        public init(
            title: String = "VAT status",
            subtitle: String? = nil,
            currencySymbol: String = "€",
            showEntries: Bool = true,
            showOnlyFlagged: Bool = true
        ) {
            self.title = title
            self.subtitle = subtitle
            self.currencySymbol = currencySymbol
            self.showEntries = showEntries
            self.showOnlyFlagged = showOnlyFlagged
        }
    }

    static func renderVATStatusHTML(
        _ report: VATStatusReport,
        options: VATStatusOptions = .init()
    ) -> String {
        let css = StatementStyleCSS.base().render()

        let quarters = options.showOnlyFlagged
            ? report.flaggedQuarters
            : report.quarters

        let doc = HTML.document {
            HTML.html(["lang": "nl"]) {
                HTML.head {
                    HTML.meta(.charset())
                    HTML.meta(.viewport())
                    HTML.title(options.title)
                    HTML.style(css)
                }

                HTML.body(["class": "sr-vat-status"]) {
                    HTML.h1 {
                        HTML.text(options.title)
                    }

                    if let subtitle = options.subtitle {
                        HTML.div(["class": "subtitle"]) {
                            HTML.text(subtitle)
                        }
                    }

                    HTML.table(["class": "tbl tbl-vat-status-summary"]) {
                        HTML.tbody {
                            renderVATStatusSummaryRow(
                                "Latest residual owed",
                                report.latestDisplayResidualOwed,
                                currencySymbol: options.currencySymbol
                            )
                            renderVATStatusSummaryRow(
                                "Latest residual receivable",
                                report.latestDisplayResidualReceivable,
                                currencySymbol: options.currencySymbol
                            )
                        }
                    }

                    if quarters.isEmpty {
                        HTML.div(["class": "summary"]) {
                            HTML.text("(no quarters)")
                        }
                    } else {
                        for quarter in quarters {
                            HTML.section(["class": "sr-vat-status-quarter"]) {
                                HTML.h2 {
                                    HTML.text(
                                        "\(quarter.period.year)Q\(quarter.period.quarter.rawValue)"
                                    )
                                }

                                HTML.table(["class": "tbl tbl-vat-status-quarter"]) {
                                    HTML.tbody {
                                        renderVATStatusSummaryRow(
                                            "Carry in",
                                            quarter.carryIn,
                                            currencySymbol: options.currencySymbol
                                        )
                                        renderVATStatusSummaryRow(
                                            "Ordinary net",
                                            quarter.ordinaryNet,
                                            currencySymbol: options.currencySymbol
                                        )
                                        renderVATStatusSummaryRow(
                                            "Output",
                                            quarter.outputNet,
                                            currencySymbol: options.currencySymbol
                                        )
                                        renderVATStatusSummaryRow(
                                            "Deductible",
                                            quarter.deductibleNet,
                                            currencySymbol: options.currencySymbol
                                        )
                                        renderVATStatusSummaryRow(
                                            "Private use",
                                            quarter.privateUseNet,
                                            currencySymbol: options.currencySymbol
                                        )
                                        renderVATStatusSummaryRow(
                                            "Receivable",
                                            quarter.receivableNet,
                                            currencySymbol: options.currencySymbol
                                        )
                                        renderVATStatusSummaryRow(
                                            "Payable fallback",
                                            quarter.payableFallbackNet,
                                            currencySymbol: options.currencySymbol
                                        )
                                        renderVATStatusSummaryRow(
                                            "Corrections net",
                                            quarter.correctionsNet,
                                            currencySymbol: options.currencySymbol
                                        )
                                        renderVATStatusSummaryRow(
                                            "Expected before settle",
                                            quarter.expectedSettlementNet,
                                            currencySymbol: options.currencySymbol
                                        )
                                        renderVATStatusSummaryRow(
                                            "Paid",
                                            quarter.paid,
                                            currencySymbol: options.currencySymbol
                                        )
                                        renderVATStatusSummaryRow(
                                            "Received",
                                            quarter.received,
                                            currencySymbol: options.currencySymbol
                                        )
                                        renderVATStatusSummaryRow(
                                            "Settlement net",
                                            quarter.settlementNet,
                                            currencySymbol: options.currencySymbol
                                        )
                                        renderVATStatusSummaryRow(
                                            "Residual",
                                            quarter.residual,
                                            currencySymbol: options.currencySymbol
                                        )
                                        renderVATStatusSummaryRow(
                                            "Residual owed",
                                            quarter.displayResidualOwed,
                                            currencySymbol: options.currencySymbol
                                        )
                                        renderVATStatusSummaryRow(
                                            "Residual receivable",
                                            quarter.displayResidualReceivable,
                                            currencySymbol: options.currencySymbol
                                        )
                                    }
                                }

                                if !quarter.residualContributions.isEmpty {
                                    HTML.table(["class": "tbl tbl-vat-status-residual"]) {
                                        HTML.thead {
                                            HTML.tr {
                                                HTML.th {
                                                    HTML.text("Residual source")
                                                }
                                                HTML.th(["class": "col-money"]) {
                                                    HTML.text("Amount")
                                                }
                                            }
                                        }

                                        HTML.tbody {
                                            for item in quarter.residualContributions {
                                                HTML.tr {
                                                    HTML.td {
                                                        HTML.text(
                                                            "\(item.sourcePeriod.year)Q\(item.sourcePeriod.quarter.rawValue)"
                                                        )
                                                    }
                                                    HTML.td(["class": "col-money"]) {
                                                        HTML.text(
                                                            fmtVATStatusAmount(
                                                                item.amount,
                                                                currencySymbol: options.currencySymbol
                                                            )
                                                        )
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }

                                if options.showEntries && !quarter.entries.isEmpty {
                                    HTML.table(["class": "tbl tbl-vat-status-entries"]) {
                                        HTML.thead {
                                            HTML.tr {
                                                HTML.th {
                                                    HTML.text("Kind")
                                                }
                                                HTML.th {
                                                    HTML.text("Date")
                                                }
                                                HTML.th {
                                                    HTML.text("Entry")
                                                }
                                                HTML.th {
                                                    HTML.text("VAT codes")
                                                }
                                                HTML.th(["class": "col-money"]) {
                                                    HTML.text("Amount")
                                                }
                                            }
                                        }

                                        HTML.tbody {
                                            for entry in quarter.entries {
                                                HTML.tr {
                                                    HTML.td {
                                                        HTML.text(entry.displayKind)
                                                    }
                                                    HTML.td {
                                                        HTML.text(
                                                            fmtVATStatusDate(entry.postingDate)
                                                        )
                                                    }
                                                    HTML.td {
                                                        HTML.text(
                                                            entry.entryId.map(String.init) ?? "—"
                                                        )
                                                    }
                                                    HTML.td {
                                                        HTML.text(
                                                            entry.vatAccountCodes.isEmpty
                                                                ? "—"
                                                                : entry.vatAccountCodes.joined(separator: ", ")
                                                        )
                                                    }
                                                    HTML.td(["class": "col-money"]) {
                                                        HTML.text(
                                                            fmtVATStatusAmount(
                                                                entry.amount,
                                                                currencySymbol: options.currencySymbol
                                                            )
                                                        )
                                                    }
                                                }

                                                if let details = entry.details,
                                                   !details.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                                    HTML.tr(["class": "vat-status-entry-details"]) {
                                                        HTML.td(["colspan": "5"]) {
                                                            HTML.text(details)
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
            }
        }

        return doc.render(
            default: HTMLDocument.RenderDefault.minified,
            doctype: true
        )
    }

    @HTMLBuilder
    private static func renderVATStatusSummaryRow(
        _ label: String,
        _ value: Decimal,
        currencySymbol: String
    ) -> [any HTMLNode] {
        HTML.tr {
            HTML.td(["class": "col-label"]) {
                HTML.text(label)
            }

            HTML.td(["class": "col-money"]) {
                HTML.text(
                    fmtVATStatusAmount(
                        value,
                        currencySymbol: currencySymbol
                    )
                )
            }
        }
    }
}

@inline(__always)
private func fmtVATStatusAmount(
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

@inline(__always)
private func fmtVATStatusDate(
    _ date: Date
) -> String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter.string(from: date)
}
