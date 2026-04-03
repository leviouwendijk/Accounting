import Foundation
import HTML
import CSS

public extension StatementHTMLRenderer {
    struct VATAuditOptions: Sendable {
        public var title: String
        public var subtitle: String?
        public var currencySymbol: String
        public var showEntries: Bool
        public var showOnlyFlagged: Bool

        public init(
            title: String = "VAT audit trail",
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

    static func renderVATAuditHTML(
        _ report: VATAuditReport,
        options: VATAuditOptions = .init()
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

                HTML.body(["class": "sr-vat-audit"]) {
                    HTML.h1 {
                        HTML.text(options.title)
                    }

                    if let subtitle = options.subtitle {
                        HTML.div(["class": "subtitle"]) {
                            HTML.text(subtitle)
                        }
                    }

                    HTML.table(["class": "tbl tbl-vat-audit-summary"]) {
                        HTML.tbody {
                            renderSummaryRow(
                                "Ledger owed",
                                report.totalLedgerOwed,
                                currencySymbol: options.currencySymbol
                            )
                            renderSummaryRow(
                                "Ledger receivable",
                                report.totalLedgerReceivable,
                                currencySymbol: options.currencySymbol
                            )
                            renderSummaryRow(
                                "Ledger net",
                                report.totalLedgerNet,
                                currencySymbol: options.currencySymbol
                            )
                            renderSummaryRow(
                                "Filed",
                                report.totalFiled,
                                currencySymbol: options.currencySymbol
                            )
                            renderSummaryRow(
                                "Paid",
                                report.totalPaid,
                                currencySymbol: options.currencySymbol
                            )
                            renderSummaryRow(
                                "Refunded",
                                report.totalRefunded,
                                currencySymbol: options.currencySymbol
                            )
                            renderSummaryRow(
                                "Corrected",
                                report.totalCorrected,
                                currencySymbol: options.currencySymbol
                            )
                            renderSummaryRow(
                                "Ledger vs declared Δ",
                                report.totalLedgerVsDeclaredDelta,
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
                            HTML.section(["class": "sr-vat-audit-quarter"]) {
                                HTML.h2 {
                                    HTML.text(
                                        "\(quarter.period.year)Q\(quarter.period.quarter.rawValue)"
                                    )
                                }

                                HTML.table(["class": "tbl tbl-vat-audit-quarter"]) {
                                    HTML.tbody {
                                        renderSummaryRow(
                                            "Ledger owed",
                                            quarter.ledgerOwed,
                                            currencySymbol: options.currencySymbol
                                        )
                                        renderSummaryRow(
                                            "Ledger receivable",
                                            quarter.ledgerReceivable,
                                            currencySymbol: options.currencySymbol
                                        )
                                        renderSummaryRow(
                                            "Ledger net",
                                            quarter.ledgerNet,
                                            currencySymbol: options.currencySymbol
                                        )
                                        renderSummaryRow(
                                            "Filed",
                                            quarter.filed,
                                            currencySymbol: options.currencySymbol
                                        )
                                        renderSummaryRow(
                                            "Paid",
                                            quarter.paid,
                                            currencySymbol: options.currencySymbol
                                        )
                                        renderSummaryRow(
                                            "Refunded",
                                            quarter.refunded,
                                            currencySymbol: options.currencySymbol
                                        )
                                        renderSummaryRow(
                                            "Corrected",
                                            quarter.corrected,
                                            currencySymbol: options.currencySymbol
                                        )
                                        renderSummaryRow(
                                            "Ledger vs declared Δ",
                                            quarter.ledgerVsDeclaredDelta,
                                            currencySymbol: options.currencySymbol
                                        )
                                    }
                                }

                                if options.showEntries && !quarter.entries.isEmpty {
                                    HTML.table(["class": "tbl tbl-vat-audit-entries"]) {
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
                                                        HTML.text(entry.kind.rawValue)
                                                    }
                                                    HTML.td {
                                                        HTML.text(
                                                            fmtVATAuditDate(entry.postingDate)
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
                                                            fmtVATAuditAmount(
                                                                entry.amount,
                                                                currencySymbol: options.currencySymbol
                                                            )
                                                        )
                                                    }
                                                }

                                                if let details = entry.details,
                                                   !details.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                                    HTML.tr(["class": "vat-audit-entry-details"]) {
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
    private static func renderSummaryRow(
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
                    fmtVATAuditAmount(
                        value,
                        currencySymbol: currencySymbol
                    )
                )
            }
        }
    }
}

@inline(__always)
private func fmtVATAuditAmount(
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
private func fmtVATAuditDate(
    _ date: Date
) -> String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter.string(from: date)
}
