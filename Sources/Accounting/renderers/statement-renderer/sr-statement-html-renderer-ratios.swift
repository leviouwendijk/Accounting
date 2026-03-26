import Foundation
import HTML

extension StatementHTMLRenderer {
    @HTMLBuilder
    static func renderRatiosSection(
        _ section: RatiosSection?
    ) -> [any HTMLNode] {
        if let section {
            HTML.section(["class": "sr-section sr-section-ratios sr-print-page-break-before"]) {
                HTML.h2 {
                    HTML.text(section.title)
                }

                HTML.table(["class": "tbl"]) {
                    HTML.thead {
                        HTML.tr {
                            HTML.th(["class": "col-label"]) {
                                HTML.text("Ratio")
                            }
                            HTML.th(["class": "col-amt"]) {
                                HTML.text("Waarde")
                            }
                        }
                    }

                    HTML.tbody {
                        for row in section.rows {
                            HTML.tr(["class": "ratio-row"]) {
                                HTML.td(["class": "label"]) {
                                    HTML.text(row.label)
                                }

                                HTML.td(["class": "amt"]) {
                                    if let value = row.value {
                                        HTML.text(formatRatio(value, style: row.style))
                                    } else {
                                        HTML.text("—")
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    static func formatRatio(
        _ value: Decimal,
        style: RatioValueStyle
    ) -> String {
        let number = NSDecimalNumber(decimal: value)

        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "nl_NL")
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2

        switch style {
        case .percentage:
            formatter.numberStyle = .percent
            return formatter.string(from: number) ?? "\(number)"

        case .multiple:
            formatter.numberStyle = .decimal
            let base = formatter.string(from: number) ?? "\(number)"
            return "\(base)x"
        }
    }
}
