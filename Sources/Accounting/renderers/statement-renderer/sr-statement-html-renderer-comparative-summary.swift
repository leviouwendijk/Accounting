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

                HTML.div(["class": "sr-summary sr-summary-comparative"]) {
                    HTML.div(["class": "sr-summary-comparative-head"]) {
                        HTML.div(["class": "sr-summary-comparative-head-item is-label"]) {
                            HTML.text("Post")
                        }

                        HTML.div(["class": "sr-summary-comparative-head-item is-amount"]) {
                            HTML.text(summary.currentTitle)
                        }

                        HTML.div(["class": "sr-summary-comparative-head-item is-amount"]) {
                            HTML.text(summary.previousTitle)
                        }
                    }

                    renderComparativeSummaryStandaloneRow(
                        label: "Som activa",
                        currentAmount: summary.currentAssets,
                        previousAmount: summary.previousAssets
                    )

                    HTML.div(["class": "sr-summary-group sr-summary-comparative-group"]) {
                        renderComparativeSummaryStandaloneRow(
                            label: "Som vermogen + passiva",
                            currentAmount: summary.currentEquityPlusLiabilities,
                            previousAmount: summary.previousEquityPlusLiabilities,
                            rowClass: "sr-summary-row-parent"
                        )

                        HTML.div(["class": "sr-summary-children sr-summary-comparative-children"]) {
                            renderComparativeSummaryStandaloneRow(
                                label: "vermogen",
                                currentAmount: summary.currentEquity,
                                previousAmount: summary.previousEquity,
                                rowClass: "sr-summary-row-child"
                            )

                            renderComparativeSummaryStandaloneRow(
                                label: "passiva",
                                currentAmount: summary.currentLiabilities,
                                previousAmount: summary.previousLiabilities,
                                rowClass: "sr-summary-row-child"
                            )
                        }
                    }

                    if shouldRenderComparativeSummaryDiff(summary) {
                        renderComparativeSummaryStandaloneRow(
                            label: "Verschil",
                            currentAmount: summary.currentDiff,
                            previousAmount: summary.previousDiff,
                            rowClass: "sr-summary-row-diff"
                        )
                    }
                }
            }
        }
    }

    @HTMLBuilder
    static func renderComparativeSummaryStandaloneRow(
        label: String,
        currentAmount: Decimal?,
        previousAmount: Decimal?,
        rowClass: String? = nil
    ) -> [any HTMLNode] {
        let cls = [
            "sr-summary-row",
            "sr-summary-comparative-row",
            rowClass
        ]
        .compactMap { $0 }
        .joined(separator: " ")

        HTML.div(["class": cls]) {
            HTML.span(["class": "sr-summary-label sr-summary-comparative-label"]) {
                HTML.text(label)
            }

            HTML.span(["class": comparativeSummaryValueClass(amount: currentAmount, rowClass: rowClass)]) {
                renderComparativeSummaryAmountNode(
                    currentAmount,
                    rowClass: rowClass
                )
            }

            HTML.span(["class": comparativeSummaryValueClass(amount: previousAmount, rowClass: rowClass)]) {
                renderComparativeSummaryAmountNode(
                    previousAmount,
                    rowClass: rowClass
                )
            }
        }
    }

    static func renderComparativeSummaryAmountNode(
        _ amount: Decimal?,
        rowClass: String? = nil
    ) -> any HTMLNode {
        guard let amount else {
            return HTML.text("—")
        }

        return HTML.text(fmt(amount))
    }

    @inline(__always)
    static func comparativeSummaryValueClass(
        amount: Decimal?,
        rowClass: String?
    ) -> String {
        var classes = [
            "sr-summary-value",
            "sr-summary-comparative-value"
        ]

        if rowClass == "sr-summary-row-child" {
            classes.append("sr-summary-value-child")
        }

        if rowClass == "sr-summary-row-diff", let amount, amount != 0 {
            classes.append("sr-summary-value-warn")
            classes.append("sr-summary-comparative-value-warn")
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


// import Foundation
// import HTML

// extension StatementHTMLRenderer {
//     @HTMLBuilder
//     static func renderComparativeSummary(
//         _ summary: ComparativeBalanceSummary?
//     ) -> [any HTMLNode] {
//         if let summary {
//             HTML.section(["class": "sr-section sr-section-summary"]) {
//                 HTML.h2 {
//                     HTML.text("Balanssamenvatting")
//                 }

//                 HTML.table(["class": "tbl tbl-comparative"]) {
//                     HTML.thead {
//                         HTML.tr {
//                             HTML.th(["class": "col-label"]) {
//                                 HTML.text("Post")
//                             }
//                             HTML.th(["class": "col-amt"]) {
//                                 HTML.text(summary.currentTitle)
//                             }
//                             HTML.th(["class": "col-amt"]) {
//                                 HTML.text(summary.previousTitle)
//                             }
//                         }
//                     }

//                     HTML.tbody {
//                         renderComparativeSummaryRow(
//                             label: "Som activa",
//                             currentAmount: summary.currentAssets,
//                             previousAmount: summary.previousAssets
//                         )

//                         renderComparativeSummaryRow(
//                             label: "Som vermogen + passiva",
//                             currentAmount: summary.currentEquityPlusLiabilities,
//                             previousAmount: summary.previousEquityPlusLiabilities,
//                             isTotal: true
//                         )

//                         renderComparativeSummaryRow(
//                             label: "vermogen",
//                             currentAmount: summary.currentEquity,
//                             previousAmount: summary.previousEquity
//                         )

//                         renderComparativeSummaryRow(
//                             label: "passiva",
//                             currentAmount: summary.currentLiabilities,
//                             previousAmount: summary.previousLiabilities
//                         )

//                         if shouldRenderComparativeSummaryDiff(summary) {
//                             renderComparativeSummaryRow(
//                                 label: "Verschil",
//                                 currentAmount: summary.currentDiff,
//                                 previousAmount: summary.previousDiff,
//                                 isTotal: true
//                             )
//                         }
//                     }
//                 }
//             }
//         }
//     }

//     @HTMLBuilder
//     static func renderComparativeSummaryRow(
//         label: String,
//         currentAmount: Decimal?,
//         previousAmount: Decimal?,
//         isTotal: Bool = false
//     ) -> [any HTMLNode] {
//         HTML.tr(isTotal ? ["class": "total"] : [:]) {
//             HTML.td(["class": "label"]) {
//                 if isTotal {
//                     HTML.strong {
//                         HTML.text(label)
//                     }
//                 } else {
//                     HTML.text(label)
//                 }
//             }

//             HTML.td(["class": "amt"]) {
//                 renderComparativeSummaryAmountNode(
//                     currentAmount,
//                     isTotal: isTotal
//                 )
//             }

//             HTML.td(["class": "amt"]) {
//                 renderComparativeSummaryAmountNode(
//                     previousAmount,
//                     isTotal: isTotal
//                 )
//             }
//         }
//     }

//     static func renderComparativeSummaryAmountNode(
//         _ amount: Decimal?,
//         isTotal: Bool = false
//     ) -> any HTMLNode {
//         guard let amount else {
//             return HTML.span(["class": "sr-amount"]) {
//                 HTML.text("—")
//             }
//         }

//         if isTotal {
//             return HTML.strong {
//                 HTML.text(fmt(amount))
//             }
//         }

//         return HTML.span(["class": "sr-amount"]) {
//             HTML.text(fmt(amount))
//         }
//     }

//     @inline(__always)
//     static func shouldRenderComparativeSummaryDiff(
//         _ summary: ComparativeBalanceSummary
//     ) -> Bool {
//         if summary.currentDiff != 0 {
//             return true
//         }

//         if let previousDiff = summary.previousDiff, previousDiff != 0 {
//             return true
//         }

//         return false
//     }
// }
