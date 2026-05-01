import Accounting
import Foundation
import HTML

extension StatementHTMLRenderer {
    @HTMLBuilder
    static func renderComparativeAveragesSection(
        _ section: ComparativeAveragesSection?
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
                                HTML.text("Gemiddelde")
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

                                        if let description = row.description,
                                           !description.isEmpty {
                                            HTML.div(["class": "ratio-description"]) {
                                                HTML.text(description)
                                            }
                                        }
                                    }
                                }

                                HTML.td(["class": "amt"]) {
                                    renderComparativeAverageValueNode(
                                        row.currentValue
                                    )
                                }

                                HTML.td(["class": "amt"]) {
                                    renderComparativeAverageValueNode(
                                        row.previousValue
                                    )
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    static func renderComparativeAverageValueNode(
        _ value: Decimal?
    ) -> any HTMLNode {
        if let value {
            return HTML.text(fmt(value))
        }

        return HTML.text("—")
    }
}
