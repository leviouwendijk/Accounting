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
                    ".tbl-comparative-summary .summary-child",
                    decl("padding-left", "24px"),
                    decl("color", "#5b6475")
                ),
                rule(
                    ".tbl-comparative-summary .summary-diff-amt",
                    decl("color", "#b42318"),
                    decl("font-weight", "700")
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
