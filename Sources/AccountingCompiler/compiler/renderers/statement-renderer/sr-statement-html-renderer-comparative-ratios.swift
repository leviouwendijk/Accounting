import Accounting
import Foundation
import HTML

extension StatementHTMLRenderer {
    @HTMLBuilder
    static func renderComparativeRatiosSection(
        _ section: ComparativeRatiosSection?
    ) -> [any HTMLNode] {
        if let section {
            HTML.section(["class": "sr-section sr-section-ratios sr-print-page-break-before"]) {
                HTML.h2 {
                    HTML.text(section.title)
                }

                HTML.table(["class": "tbl tbl-comparative"]) {
                    HTML.thead {
                        HTML.tr {
                            HTML.th(["class": "col-label"]) {
                                HTML.text("Ratio")
                            }
                            HTML.th(["class": "col-amt"]) {
                                HTML.text(section.currentTitle)
                            }
                            HTML.th(["class": "col-amt"]) {
                                HTML.text(section.previousTitle)
                            }
                        }
                    }

                    HTML.tbody {
                        for row in section.rows {
                            HTML.tr(["class": "ratio-row"]) {
                                HTML.td(["class": "label"]) {
                                    HTML.div(["class": "ratio-label-stack"]) {
                                        HTML.div(["class": "ratio-label-main"]) {
                                            HTML.text(row.label)
                                        }

                                        if let description = row.description, !description.isEmpty {
                                            HTML.div(["class": "ratio-description"]) {
                                                HTML.text(description)
                                            }
                                        }

                                        if let formula = row.formula, !formula.isEmpty {
                                            HTML.div(["class": "ratio-formula"]) {
                                                HTML.text(formula)
                                            }
                                        }
                                    }
                                }

                                HTML.td(["class": "amt"]) {
                                    renderComparativeRatioValueNode(
                                        row.currentValue,
                                        style: row.style
                                    )
                                }

                                HTML.td(["class": "amt"]) {
                                    renderComparativeRatioValueNode(
                                        row.previousValue,
                                        style: row.style
                                    )
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    static func renderComparativeRatioValueNode(
        _ value: Decimal?,
        style: RatioValueStyle
    ) -> any HTMLNode {
        if let value {
            return HTML.text(
                formatRatio(value, style: style)
            )
        }

        return HTML.text("—")
    }
}
