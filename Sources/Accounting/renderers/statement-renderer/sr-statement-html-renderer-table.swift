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

                    renderTableSection(model.income)

                    for section in model.balances {
                        renderTableSection(section)
                    }

                    renderSummary(model.summary)
                }
            }
        }

        return doc.render(default: .pretty, doctype: true)
    }

    @HTMLBuilder
    static func renderTableSection(
        _ section: TableSection
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
                    renderTableRow(row)
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
        _ row: TableRow
    ) -> [any HTMLNode] {
        HTML.tr {
            HTML.td(["class": "label"]) {
                renderLabelCell(
                    label: row.label,
                    indent: row.indent,
                    isTotal: row.isTotal
                )
            }

            HTML.td(["class": "amt"]) {
                renderAmountCell(
                    amount: row.amount,
                    indent: row.indent,
                    isTotal: row.isTotal
                )
            }
        }
    }

    static func renderLabelCell(
        label: String,
        indent: Int,
        isTotal: Bool
    ) -> any HTMLNode {
        HTML.div([
            "class": rowLabelClass(indent: indent)
        ]) {
            HTML.raw(indentationPrefix(indent))

            if isTotal {
                HTML.strong {
                    HTML.text(escape(label))
                }
            } else {
                HTML.text(escape(label))
            }
        }
    }

    static func renderAmountCell(
        amount: Decimal,
        indent: Int,
        isTotal: Bool
    ) -> any HTMLNode {
        let text = fmt(amount)

        return HTML.span([
            "class": rowAmountClass(indent: indent)
        ]) {
            if isTotal {
                HTML.strong {
                    HTML.text(text)
                }
            } else {
                HTML.text(text)
            }
        }
    }
}
