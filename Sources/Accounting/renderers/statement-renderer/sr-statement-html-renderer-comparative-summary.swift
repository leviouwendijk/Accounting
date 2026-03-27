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

                HTML.table(["class": "tbl tbl-comparative"]) {
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
                            isTotal: true
                        )

                        renderComparativeSummaryRow(
                            label: "vermogen",
                            currentAmount: summary.currentEquity,
                            previousAmount: summary.previousEquity
                        )

                        renderComparativeSummaryRow(
                            label: "passiva",
                            currentAmount: summary.currentLiabilities,
                            previousAmount: summary.previousLiabilities
                        )

                        if shouldRenderComparativeSummaryDiff(summary) {
                            renderComparativeSummaryRow(
                                label: "Verschil",
                                currentAmount: summary.currentDiff,
                                previousAmount: summary.previousDiff,
                                isTotal: true
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
        isTotal: Bool = false
    ) -> [any HTMLNode] {
        HTML.tr(isTotal ? ["class": "total"] : [:]) {
            HTML.td(["class": "label"]) {
                if isTotal {
                    HTML.strong {
                        HTML.text(label)
                    }
                } else {
                    HTML.text(label)
                }
            }

            HTML.td(["class": "amt"]) {
                renderComparativeSummaryAmountNode(
                    currentAmount,
                    isTotal: isTotal
                )
            }

            HTML.td(["class": "amt"]) {
                renderComparativeSummaryAmountNode(
                    previousAmount,
                    isTotal: isTotal
                )
            }
        }
    }

    static func renderComparativeSummaryAmountNode(
        _ amount: Decimal?,
        isTotal: Bool = false
    ) -> any HTMLNode {
        guard let amount else {
            return HTML.span(["class": "sr-amount"]) {
                HTML.text("—")
            }
        }

        if isTotal {
            return HTML.strong {
                HTML.text(fmt(amount))
            }
        }

        return HTML.span(["class": "sr-amount"]) {
            HTML.text(fmt(amount))
        }
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
