import Foundation
import HTML

extension StatementHTMLRenderer {
    @HTMLBuilder
    static func renderComparativeSummary(
        _ summary: ComparativeBalanceSummary?
    ) -> [any HTMLNode] {
        if let summary {
            HTML.section(["class": "sr-section sr-section-summary"]) {
                HTML.h2 {
                    HTML.text("Balanssamenvatting")
                }

                HTML.table(["class": "tbl tbl-comparative tbl-comparative-summary"]) {
                    HTML.thead {
                        HTML.tr {
                            HTML.th(["class": "col-label"]) {
                                HTML.text("Post")
                            }

                            HTML.th(["class": "col-amt"]) {
                                HTML.text(summary.currentTitle)
                            }

                            HTML.th(["class": "col-amt"]) {
                                HTML.text(summary.previousTitle)
                            }
                        }
                    }

                    HTML.tbody {
                        renderComparativeSummaryRow(
                            label: "Som activa",
                            currentAmount: summary.currentAssets,
                            previousAmount: summary.previousAssets
                        )

                        renderComparativeSummaryRow(
                            label: "Som vermogen + passiva",
                            currentAmount: summary.currentEquityPlusLiabilities,
                            previousAmount: summary.previousEquityPlusLiabilities,
                            rowClass: "summary-parent"
                        )

                        renderComparativeSummaryRow(
                            label: "vermogen",
                            currentAmount: summary.currentEquity,
                            previousAmount: summary.previousEquity,
                            rowClass: "summary-child-row",
                            labelClass: "summary-child"
                        )

                        renderComparativeSummaryRow(
                            label: "passiva",
                            currentAmount: summary.currentLiabilities,
                            previousAmount: summary.previousLiabilities,
                            rowClass: "summary-child-row",
                            labelClass: "summary-child"
                        )

                        if shouldRenderComparativeSummaryDiff(summary) {
                            renderComparativeSummaryRow(
                                label: "Verschil",
                                currentAmount: summary.currentDiff,
                                previousAmount: summary.previousDiff,
                                rowClass: "summary-diff"
                            )
                        }
                    }
                }
            }
        }
    }

    @HTMLBuilder
    static func renderComparativeSummaryRow(
        label: String,
        currentAmount: Decimal?,
        previousAmount: Decimal?,
        rowClass: String? = nil,
        labelClass: String? = nil
    ) -> [any HTMLNode] {
        let trAttrs: HTMLAttribute =
            if let rowClass, !rowClass.isEmpty {
                ["class": rowClass]
            } else {
                [:]
            }

        let tdLabelClass = [
            "label",
            labelClass
        ]
        .compactMap { $0 }
        .joined(separator: " ")

        HTML.tr(trAttrs) {
            HTML.td(["class": tdLabelClass]) {
                renderComparativeSummaryLabelNode(label)
            }

            HTML.td([
                "class": comparativeSummaryAmountCellClass(
                    amount: currentAmount,
                    rowClass: rowClass
                )
            ]) {
                renderComparativeSummaryAmountNode(currentAmount)
            }

            HTML.td([
                "class": comparativeSummaryAmountCellClass(
                    amount: previousAmount,
                    rowClass: rowClass
                )
            ]) {
                renderComparativeSummaryAmountNode(previousAmount)
            }
        }
    }

    static func renderComparativeSummaryLabelNode(
        _ label: String
    ) -> any HTMLNode {
        HTML.text(label)
    }

    static func renderComparativeSummaryAmountNode(
        _ amount: Decimal?
    ) -> any HTMLNode {
        guard let amount else {
            return HTML.span(["class": "sr-amount"]) {
                HTML.text("—")
            }
        }

        return HTML.span(["class": "sr-amount"]) {
            HTML.text(fmt(amount))
        }
    }

    @inline(__always)
    static func comparativeSummaryAmountCellClass(
        amount: Decimal?,
        rowClass: String?
    ) -> String {
        var classes = ["amt"]

        if rowClass == "summary-diff",
           let amount,
           amount != 0 {
            classes.append("summary-diff-amt")
        }

        return classes.joined(separator: " ")
    }

    @inline(__always)
    static func shouldRenderComparativeSummaryDiff(
        _ summary: ComparativeBalanceSummary
    ) -> Bool {
        if summary.currentDiff != 0 {
            return true
        }

        if let previousDiff = summary.previousDiff, previousDiff != 0 {
            return true
        }

        return false
    }
}
