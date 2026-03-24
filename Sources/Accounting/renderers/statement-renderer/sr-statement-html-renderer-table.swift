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
                    // renderSummary(
                    //     renderedBalanceSummary(from: model.balances)
                    // )
                    renderRatiosSection(model.ratios)
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
        HTML.section(["class": section.renderedSectionClassName]) {
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
                            sectionKind: section.kind,
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
    }

    @HTMLBuilder
    static func renderTableRow(
        _ row: TableRow,
        sectionKind: TableSectionKind,
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
                renderAmountCell(
                    row: row,
                    sectionKind: sectionKind
                )
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
        row: TableRow,
        sectionKind: TableSectionKind
    ) -> any HTMLNode {
        let shown = displayedAmount(
            row: row,
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

extension StatementHTMLRenderer {
    static func renderedBalanceSummary(
        from sections: [TableSection]
    ) -> BalanceSummary? {
        var assets: Decimal?
        var equity: Decimal?
        var liabilities: Decimal?

        for section in sections {
            guard case .balance(let kind) = section.kind else {
                continue
            }

            let total = section.rows.reduce(Decimal(0)) { partial, row in
                partial + displayedAmount(
                    row: row,
                    sectionKind: section.kind
                )
            }

            switch kind {
            case .assets:
                assets = total
            case .equity:
                equity = total
            case .liabilities:
                liabilities = total
            case .other:
                break
            }
        }

        guard let assets, let equity, let liabilities else {
            return nil
        }

        return BalanceSummary(
            assets: assets,
            equity: equity,
            liabilities: liabilities
        )
    }
}
