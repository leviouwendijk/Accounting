import Accounting
import Foundation
import HTML
import CSS

extension StatementHTMLRenderer {
    static func renderComparativeDocument(
        model: ComparativeDocumentModel,
        options: Options
    ) -> String {
        let css = CSSStyleSheet(
            StatementStyleCSS.base(),
            comparativeTableStyleSheet()
        ).render()

        let doc = HTML.document {
            HTML.html(["lang": "nl"]) {
                HTML.head {
                    HTML.meta(.charset())
                    HTML.meta(.viewport())
                    HTML.title(options.title)
                    HTML.style(css)
                }

                HTML.body {
                    renderDocumentHeader(options: options)

                    renderComparativeTableSection(
                        model.income,
                        options: options
                    )

                    for section in model.balances {
                        renderComparativeTableSection(
                            section,
                            options: options
                        )
                    }

                    renderComparativeSummary(model.summary)

                    if options.showRatios {
                        renderComparativeRatiosSection(model.ratios)
                    }

                    if options.showAverages {
                        renderComparativeAveragesSection(model.averages)
                    }
                }
            }
        }

        return doc.render(default: .minified, doctype: true)
    }

    static func comparativeTableStyleSheet() -> CSSStyleSheet {
        stylesheet(
            rules: [
                rule(
                    ".tbl-comparative thead .col-amt",
                    decl("white-space", "normal"),
                    decl("min-width", "10ch")
                ),
                rule(
                    ".tbl-comparative .col-label",
                    decl("width", "auto")
                ),

                rule(
                    ".tbl-comparative-summary",
                    decl("width", "100%"),
                    decl("border-collapse", "separate"),
                    decl("border-spacing", "0"),
                    decl("background", "#f7f7f8"),
                    decl("border", "1px solid #d9dee4"),
                    decl("border-radius", "18px"),
                    decl("overflow", "hidden")
                ),
                rule(
                    ".tbl-comparative-summary thead",
                    decl("display", "none")
                ),
                rule(
                    ".tbl-comparative-summary tbody tr:first-child td",
                    decl("padding-top", "18px")
                ),
                rule(
                    ".tbl-comparative-summary tbody tr:last-child td",
                    decl("padding-bottom", "18px")
                ),
                rule(
                    ".tbl-comparative-summary td",
                    decl("padding", "10px 26px"),
                    decl("vertical-align", "middle"),
                    decl("border", "none"),
                    decl("background", "transparent")
                ),
                rule(
                    ".tbl-comparative-summary td.label",
                    decl("color", "#4b5563")
                ),
                rule(
                    ".tbl-comparative-summary td.amt",
                    decl("text-align", "right"),
                    decl("white-space", "nowrap"),
                    decl("font-variant-numeric", "tabular-nums"),
                    decl("color", "#111827")
                ),
                rule(
                    ".tbl-comparative-summary tr.summary-parent td",
                    decl("padding-top", "18px")
                ),
                rule(
                    ".tbl-comparative-summary tr.summary-parent td",
                    decl("border-top", "1px solid #d9dee4")
                ),
                rule(
                    ".tbl-comparative-summary td.label.summary-child",
                    decl("padding-left", "48px"),
                    decl("color", "#6b7280")
                ),
                rule(
                    ".tbl-comparative-summary tr.summary-child-row td",
                    decl("padding-top", "6px"),
                    decl("padding-bottom", "6px")
                ),
                rule(
                    ".tbl-comparative-summary tr.summary-parent td.label",
                    decl("color", "#4b5563")
                ),
                rule(
                    ".tbl-comparative-summary tr.summary-parent td.amt",
                    decl("font-weight", "400")
                ),
                rule(
                    ".tbl-comparative-summary .summary-diff-amt",
                    decl("color", "#b42318"),
                    decl("font-weight", "600")
                ),
                rule(
                    ".tbl-comparative-summary tr.summary-diff td.label",
                    decl("color", "#b42318")
                )
            ],
            media: [
                media(
                    "(max-width: 720px)",
                    rule(
                        ".tbl-comparative-summary td",
                        decl("padding", "8px 14px")
                    ),
                    rule(
                        ".tbl-comparative-summary td.label.summary-child",
                        decl("padding-left", "28px")
                    )
                )
            ]
        )
    }

    @HTMLBuilder
    static func renderComparativeTableSection(
        _ section: ComparativeSection,
        options: Options
    ) -> [any HTMLNode] {
        HTML.section(["class": section.renderedSectionClassName]) {
            HTML.h2 {
                HTML.text(section.title)
            }

            HTML.table(["class": "tbl tbl-comparative"]) {
                HTML.thead {
                    HTML.tr {
                        HTML.th(["class": "col-label"]) {
                            HTML.text("Naam")
                        }

                        for column in section.columns {
                            HTML.th(["class": "col-amt"]) {
                                HTML.text(column.title)
                            }
                        }
                    }
                }

                HTML.tbody {
                    for row in section.rows {
                        renderComparativeTableRow(
                            row,
                            sectionKind: section.kind,
                            options: options
                        )
                    }

                    if section.subtotalCells.contains(where: comparativeCellHasValue(_:)) {
                        HTML.tr(["class": "total"]) {
                            HTML.td(["class": "label"]) {
                                HTML.text("Som")
                            }

                            for cell in section.subtotalCells {
                                HTML.td(["class": "amt"]) {
                                    renderComparativeSubtotalNode(cell)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    @HTMLBuilder
    static func renderComparativeTableRow(
        _ row: ComparativeRow,
        sectionKind: TableSectionKind,
        options: Options
    ) -> [any HTMLNode] {
        HTML.tr {
            HTML.td(["class": "label"]) {
                renderComparativeLabelCell(
                    row: row,
                    options: options
                )
            }

            for cell in row.cells {
                HTML.td(["class": "amt"]) {
                    renderComparativeAmountNode(
                        cell,
                        row: row,
                        sectionKind: sectionKind
                    )
                }
            }
        }
    }

    static func renderComparativeLabelCell(
        row: ComparativeRow,
        options: Options
    ) -> any HTMLNode {
        var attrs: HTMLAttribute = [
            "class": rowLabelClass(depth: row.depth)
        ]

        if let style = spacingIndentStyle(
            depth: row.depth,
            options: options
        ) {
            attrs.merge(["style": style])
        }

        return HTML.div(attrs) {
            if !row.prefix.isEmpty {
                HTML.span(["class": "sr-hierarchy-prefix"]) {
                    HTML.raw(row.prefix)
                }
            }

            if row.isTotal {
                HTML.strong {
                    HTML.text(row.label)
                }
            } else {
                HTML.text(row.label)
            }
        }
    }

    static func renderComparativeAmountNode(
        _ cell: ComparativeAmountCell,
        row: ComparativeRow,
        sectionKind: TableSectionKind
    ) -> any HTMLNode {
        switch cell {
        case .blank:
            return HTML.span([
                "class": rowAmountClass(depth: row.depth)
            ]) {
                HTML.text("—")
            }

        case .value(let rawAmount):
            let shown = displayedComparativeAmount(
                rawAmount: rawAmount,
                direction: row.direction,
                orientation: row.orientation,
                sectionKind: sectionKind
            )

            let text = fmt(shown)
            let cls = shown < 0
                ? "\(rowAmountClass(depth: row.depth)) sr-amount-negative"
                : rowAmountClass(depth: row.depth)

            return HTML.span([
                "class": cls
            ]) {
                if row.isTotal {
                    HTML.strong {
                        HTML.text(text)
                    }
                } else {
                    HTML.text(text)
                }
            }
        }
    }

    static func renderComparativeSubtotalNode(
        _ cell: ComparativeAmountCell
    ) -> any HTMLNode {
        switch cell {
        case .blank:
            return HTML.span(["class": "sr-amount"]) {
                HTML.text("—")
            }

        case .value(let amount):
            return HTML.strong {
                HTML.text(fmt(amount))
            }
        }
    }

    @inline(__always)
    static func comparativeCellHasValue(
        _ cell: ComparativeAmountCell
    ) -> Bool {
        switch cell {
        case .value:
            return true

        case .blank:
            return false
        }
    }
}


// import Foundation
// import HTML

// extension StatementHTMLRenderer {
//     static func renderComparativeDocument(
//         model: ComparativeDocumentModel,
//         options: Options
//     ) -> String {
//         let css = StatementStyleCSS.base().render() + "\n" + comparativeTableCSS()

//         let doc = HTML.document {
//             HTML.html(["lang": "nl"]) {
//                 HTML.head {
//                     HTML.meta(.charset())
//                     HTML.meta(.viewport())
//                     HTML.title(options.title)
//                     HTML.style(css)
//                 }

//                 HTML.body {
//                     renderDocumentHeader(options: options)

//                     renderComparativeTableSection(
//                         model.income,
//                         options: options
//                     )

//                     for section in model.balances {
//                         renderComparativeTableSection(
//                             section,
//                             options: options
//                         )
//                     }

//                     renderComparativeSummary(model.summary)

//                     if options.showRatios {
//                         renderComparativeRatiosSection(model.ratios)
//                     }

//                     if options.showAverages {
//                         renderComparativeAveragesSection(model.averages)
//                     }
//                 }
//             }
//         }

//         return doc.render(default: .pretty, doctype: true)
//     }

//     static func comparativeTableCSS() -> String {
//         """
//         .tbl-comparative thead .col-amt {
//             white-space: normal;
//             min-width: 10ch;
//         }

//         .tbl-comparative .col-label {
//             width: auto;
//         }
//         """
//     }

//     @HTMLBuilder
//     static func renderComparativeTableSection(
//         _ section: ComparativeSection,
//         options: Options
//     ) -> [any HTMLNode] {
//         HTML.section(["class": section.renderedSectionClassName]) {
//             HTML.h2 {
//                 HTML.text(section.title)
//             }

//             HTML.table(["class": "tbl tbl-comparative"]) {
//                 HTML.thead {
//                     HTML.tr {
//                         HTML.th(["class": "col-label"]) {
//                             HTML.text("Naam")
//                         }

//                         for column in section.columns {
//                             HTML.th(["class": "col-amt"]) {
//                                 HTML.text(column.title)
//                             }
//                         }
//                     }
//                 }

//                 HTML.tbody {
//                     for row in section.rows {
//                         renderComparativeTableRow(
//                             row,
//                             sectionKind: section.kind,
//                             options: options
//                         )
//                     }

//                     if section.subtotalCells.contains(where: comparativeCellHasValue(_:)) {
//                         HTML.tr(["class": "total"]) {
//                             HTML.td(["class": "label"]) {
//                                 HTML.text("Som")
//                             }

//                             for cell in section.subtotalCells {
//                                 HTML.td(["class": "amt"]) {
//                                     renderComparativeSubtotalNode(cell)
//                                 }
//                             }
//                         }
//                     }
//                 }
//             }
//         }
//     }

//     @HTMLBuilder
//     static func renderComparativeTableRow(
//         _ row: ComparativeRow,
//         sectionKind: TableSectionKind,
//         options: Options
//     ) -> [any HTMLNode] {
//         HTML.tr {
//             HTML.td(["class": "label"]) {
//                 renderComparativeLabelCell(
//                     row: row,
//                     options: options
//                 )
//             }

//             for cell in row.cells {
//                 HTML.td(["class": "amt"]) {
//                     renderComparativeAmountNode(
//                         cell,
//                         row: row,
//                         sectionKind: sectionKind
//                     )
//                 }
//             }
//         }
//     }

//     static func renderComparativeLabelCell(
//         row: ComparativeRow,
//         options: Options
//     ) -> any HTMLNode {
//         var attrs: HTMLAttribute = [
//             "class": rowLabelClass(depth: row.depth)
//         ]

//         if let style = spacingIndentStyle(
//             depth: row.depth,
//             options: options
//         ) {
//             attrs.merge(["style": style])
//         }

//         return HTML.div(attrs) {
//             if !row.prefix.isEmpty {
//                 HTML.span(["class": "sr-hierarchy-prefix"]) {
//                     HTML.raw(row.prefix)
//                 }
//             }

//             if row.isTotal {
//                 HTML.strong {
//                     HTML.text(row.label)
//                 }
//             } else {
//                 HTML.text(row.label)
//             }
//         }
//     }

//     static func renderComparativeAmountNode(
//         _ cell: ComparativeAmountCell,
//         row: ComparativeRow,
//         sectionKind: TableSectionKind
//     ) -> any HTMLNode {
//         switch cell {
//         case .blank:
//             return HTML.span([
//                 "class": rowAmountClass(depth: row.depth)
//             ]) {
//                 HTML.text("—")
//             }

//         case .value(let rawAmount):
//             let shown = displayedComparativeAmount(
//                 rawAmount: rawAmount,
//                 direction: row.direction,
//                 orientation: row.orientation,
//                 sectionKind: sectionKind
//             )

//             let text = fmt(shown)
//             let cls = shown < 0
//                 ? "\(rowAmountClass(depth: row.depth)) sr-amount-negative"
//                 : rowAmountClass(depth: row.depth)

//             return HTML.span([
//                 "class": cls
//             ]) {
//                 if row.isTotal {
//                     HTML.strong {
//                         HTML.text(text)
//                     }
//                 } else {
//                     HTML.text(text)
//                 }
//             }
//         }
//     }

//     static func renderComparativeSubtotalNode(
//         _ cell: ComparativeAmountCell
//     ) -> any HTMLNode {
//         switch cell {
//         case .blank:
//             return HTML.span(["class": "sr-amount"]) {
//                 HTML.text("—")
//             }

//         case .value(let amount):
//             return HTML.strong {
//                 HTML.text(fmt(amount))
//             }
//         }
//     }

//     @inline(__always)
//     static func comparativeCellHasValue(
//         _ cell: ComparativeAmountCell
//     ) -> Bool {
//         switch cell {
//         case .value:
//             return true

//         case .blank:
//             return false
//         }
//     }
// }
