import Foundation
import HTML

extension StatementHTMLRenderer {
    @HTMLBuilder
    static func renderSummary(
        _ summary: BalanceSummary?
    ) -> [any HTMLNode] {
        if let summary {
            HTML.section(["class": "sr-summary"]) {
                HTML.div(["class": "sr-summary-row"]) {
                    HTML.span(["class": "sr-summary-label"]) {
                        HTML.text("Som activa")
                    }

                    HTML.span(["class": "sr-summary-value"]) {
                        HTML.text(fmt(summary.assets))
                    }
                }

                HTML.div(["class": "sr-summary-row"]) {
                    HTML.span(["class": "sr-summary-label"]) {
                        HTML.text("Som eigen vermogen + passiva")
                    }

                    HTML.span(["class": "sr-summary-value"]) {
                        HTML.text(fmt(summary.equityPlusLiabilities))
                    }
                }

                if !summary.isBalanced {
                    HTML.div(["class": "sr-summary-row sr-summary-row-diff"]) {
                        HTML.span(["class": "sr-summary-label"]) {
                            HTML.text("Verschil")
                        }

                        HTML.span(["class": "sr-summary-value sr-summary-value-warn"]) {
                            HTML.text(fmt(summary.diff))
                        }
                    }
                }
            }
        }
    }
}
