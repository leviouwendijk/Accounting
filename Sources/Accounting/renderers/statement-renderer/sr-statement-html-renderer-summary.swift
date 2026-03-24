import Foundation
import HTML

extension StatementHTMLRenderer {
    @HTMLBuilder
    static func renderSummary(
        _ summary: BalanceSummary?
    ) -> [any HTMLNode] {
        if let summary {
            HTML.div(["class": "summary"]) {
                HTML.text("Som Activa: \(fmt(summary.assets))")
            }

            HTML.div(["class": "summary"]) {
                HTML.text("Som Eigen Vermogen + Passiva: \(fmt(summary.equityPlusLiabilities))")
            }

            if !summary.isBalanced {
                HTML.div(["class": "summary"]) {
                    HTML.span(["class": "warn"]) {
                        HTML.text("DIFF: " + fmt(summary.diff))
                    }
                }
            }
        }
    }
}
