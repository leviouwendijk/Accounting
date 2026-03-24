import Foundation
import HTML

extension StatementHTMLRenderer {
    static func renderDocument(
        model: DocumentModel,
        options: Options
    ) -> String {
        let css = StatementStyleCSS.base().render()

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

                    renderTableSection(
                        model.income,
                        options: options
                    )

                    for section in model.balances {
                        renderTableSection(
                            section,
                            options: options
                        )
                    }

                    renderSummary(model.summary)
                }
            }
        }

        return doc.render(default: .pretty, doctype: true)
    }

    @HTMLBuilder
    static func renderTableSection(
        _ section: TableSection,
        options: Options
    ) -> [any HTMLNode] {
        HTML.h2 {
            HTML.text(section.title)
        }

        HTML.table(["class": "tbl"]) {
            HTML.thead {
                HTML.tr {
                    HTML.th(["class": "col-label"]) {
                        HTML.text("Naam")
                    }
                    HTML.th(["class": "col-amt"]) {
                        HTML.text("Bedrag")
                    }
                }
            }

            HTML.tbody {
                for row in section.rows {
                    renderTableRow(
                        row,
                        options: options
                    )
                }

                if let subtotal = section.subtotal {
                    HTML.tr(["class": "total"]) {
                        HTML.td(["class": "label"]) {
                            HTML.text("Som")
                        }
                        HTML.td(["class": "amt"]) {
                            HTML.strong {
                                HTML.text(fmt(subtotal))
                            }
                        }
                    }
                }
            }
        }
    }

    @HTMLBuilder
    static func renderTableRow(
        _ row: TableRow,
        options: Options
    ) -> [any HTMLNode] {
        HTML.tr {
            HTML.td(["class": "label"]) {
                renderLabelCell(
                    row: row,
                    options: options
                )
            }

            HTML.td(["class": "amt"]) {
                renderAmountCell(row: row)
            }
        }
    }

    static func renderLabelCell(
        row: TableRow,
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

    static func renderAmountCell(
        row: TableRow
    ) -> any HTMLNode {
        let text = fmt(row.amount)

        return HTML.span([
            "class": rowAmountClass(depth: row.depth)
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
