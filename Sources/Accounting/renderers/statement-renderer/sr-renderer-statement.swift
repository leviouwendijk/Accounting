import Foundation
import HTML

extension StatementHTMLRenderer {
    public static func render(
        period: PeriodAssembleResultPeriod,
        chart: CompiledChart,
        equityCode: String = "BEiv",
        options: Options = .init()
    ) throws -> String {
        var opts = options
        opts.subtitle = period.range.string()
        return try render(bundle: period.bundle, chart: chart, equityCode: equityCode, options: opts)
    }

    public static func render(
        bundle: StatementBundle,
        chart: CompiledChart,
        equityCode: String = "BEiv",
        options: Options = .init()
    ) throws -> String {
        // MODEL STEP: compute sections using your existing presenter helpers.
        let sections = try RGSPrinter.computeBalanceByL2Sections(
            bundle: bundle,
            chart: chart,
            equityCode: equityCode,
            includeOtherBucket: options.includeOtherBucket
        )

        let isSections = try RGSPrinter.incomeSections(
            bundle: bundle,
            chart: chart,
            omitLevel1Root: options.omitIncomeLevel1Root
        )

        let incomeLines = isSections.first?.lines ?? []

        @inline(__always)
        func absDec(_ d: Decimal) -> Decimal { 
            return d < 0 ? -d : d 
        }

        @inline(__always)
        func levelClass(_ level: Int) -> String {
            return "sr-level-\(min(3, max(0, level)))"
        }

        // Filter + indent, same logic as before.
        let plRows: [(indent: Int, label: String, amount: Decimal, isTotal: Bool)] =
            incomeLines
                .filter {
                    options.minAbsIncome == 0
                    ? true
                    : (absDec($0.amount) >= options.minAbsIncome)
                }
                .map { r in
                    let base = options.omitIncomeLevel1Root ? 2 : 1
                    return (
                        indent: max(0, Int(r.level) - base),
                        label: r.label,
                        amount: r.amount,
                        isTotal: false
                    )
                }

        // Formatter + escape identical to before (but used only inside renderer).
        func escape(_ s: String) -> String {
            s.replacingOccurrences(of: "&", with: "&amp;")
             .replacingOccurrences(of: "<", with: "&lt;")
             .replacingOccurrences(of: ">", with: "&gt;")
        }

        func fmt(_ d: Decimal) -> String {
            let nf = NumberFormatter()
            nf.locale = Locale(identifier: "nl_NL")
            nf.numberStyle = .decimal
            nf.minimumFractionDigits = 2
            nf.maximumFractionDigits = 2
            return nf.string(from: d as NSDecimalNumber) ?? d.description
        }

        func nonEmpty(_ s: String?) -> String? {
            guard let t = s?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !t.isEmpty
            else { return nil }
            return t
        }

        // Helper: balance section -> <h2> + table
        @HTMLBuilder
        func renderBalanceTable(
            _ title: String,
            sec: RGSBalanceBucketsOutput.Section?
        ) -> [any HTMLNode] {
            if let sec {
                HTML.h2 {
                    HTML.text(title)
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
                        // Lines
                        for line in sec.lines {
                            let pad = String(
                                repeating: "\u{00a0}\u{00a0}",
                                count: max(0, line.relativeIndent)
                            )

                            // HTML.tr {
                            //     HTML.td(["class": "label"]) {
                            //         HTML.raw(pad)
                            //         HTML.text(escape(line.label))
                            //     }
                            //     HTML.td(["class": "amt"]) {
                            //         HTML.text(fmt(line.amount))
                            //     }
                            // }
                            HTML.tr {
                                HTML.td(["class": "label"]) {
                                    HTML.div([
                                        "class": "sr-label \(levelClass(line.relativeIndent))"
                                    ]) {
                                        HTML.raw(pad)
                                        HTML.text(escape(line.label))
                                    }
                                }
                                HTML.td(["class": "amt"]) {
                                    HTML.text(fmt(line.amount))
                                }
                            }
                        }

                        // Subtotal row, if any
                        if let st = sec.subtotal {
                            HTML.tr(["class": "total"]) {
                                HTML.td(["class": "label"]) {
                                    HTML.text("Som")
                                }
                                HTML.td(["class": "amt"]) {
                                    HTML.strong {
                                        HTML.text(fmt(st))
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // Helper: company header block (normal func, not a builder)
        func companyHeader(_ c: Company, options: Options) -> any HTMLNode {
            HTML.header(["class": "doc"]) {
                // Left column
                HTML.div(["class": "company"]) {
                    let titleLeft = nonEmpty(c.name) ?? options.title
                    HTML.h1 {
                        HTML.text(escape(titleLeft))
                    }

                    if let kvk = c.kvk {
                        HTML.div(["class": "small"]) {
                            HTML.text(" \(escape(kvk))")
                        }
                    }

                    if let addr = c.address?.string, !addr.isEmpty {
                        for line in addr.split(separator: "\n") {
                            HTML.div(["class": "small"]) {
                                HTML.text(escape(String(line)))
                            }
                        }
                    }
                }

                // Right column
                HTML.div(["class": "meta"]) {
                    HTML.div(["class": "title"]) {
                        HTML.text(escape(options.title))
                    }
                    if let sub = options.subtitle {
                        HTML.div(["class": "subtitle"]) {
                            HTML.text(escape(sub))
                        }
                    }
                }
            }
        }

        // CSS from DSL
        let css = StatementStyleCSS.base().render()

        // RENDER STEP: build HTMLDocument via Constructors.
        let doc = HTML.document {
            HTML.html(["lang": "nl"]) {
                HTML.head {
                    HTML.meta(.charset())
                    HTML.meta(.viewport())
                    HTML.title(options.title)
                    HTML.style(css)
                }

                HTML.body {
                    // Header
                    if let c = options.company {
                        companyHeader(c, options: options)
                    } else {
                        HTML.h1 {
                            HTML.text(escape(options.title))
                        }
                        if let sub = options.subtitle {
                            HTML.div(["class": "subtitle"]) {
                                HTML.text(escape(sub))
                            }
                        }
                    }

                    // Winst- en verliesrekening
                    HTML.h2 {
                        HTML.text("Winst- en Verliesrekening")
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
                            for r in plRows {
                                let pad = String(
                                    repeating: "\u{00a0}\u{00a0}",
                                    count: max(0, r.indent)
                                )

                                // HTML.tr {
                                //     HTML.td(["class": "label"]) {
                                //         HTML.raw(pad)
                                //         if r.isTotal {
                                //             HTML.strong {
                                //                 HTML.text(escape(r.label))
                                //             }
                                //         } else {
                                //             HTML.text(escape(r.label))
                                //         }
                                //     }

                                //     HTML.td(["class": "amt"]) {
                                //         let txt = fmt(r.amount)
                                //         if r.isTotal {
                                //             HTML.strong {
                                //                 HTML.text(txt)
                                //             }
                                //         } else {
                                //             HTML.text(txt)
                                //         }
                                //     }
                                // }
                                HTML.tr {
                                    HTML.td(["class": "label"]) {
                                        HTML.div([
                                            "class": "sr-label \(levelClass(r.indent))"
                                        ]) {
                                            HTML.raw(pad)
                                            if r.isTotal {
                                                HTML.strong {
                                                    HTML.text(escape(r.label))
                                                }
                                            } else {
                                                HTML.text(escape(r.label))
                                            }
                                        }
                                    }

                                    HTML.td(["class": "amt"]) {
                                        let txt = fmt(r.amount)
                                        if r.isTotal {
                                            HTML.strong {
                                                HTML.text(txt)
                                            }
                                        } else {
                                            HTML.text(txt)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Balance sheet sections (Activa / Eigen Vermogen / Passiva / Other)
                    renderBalanceTable("Balans: Activa",         sec: sections.assets)
                    renderBalanceTable("Balans: Eigen Vermogen", sec: sections.equity)
                    renderBalanceTable("Balans: Passiva",        sec: sections.liabilities)

                    if options.includeOtherBucket {
                        renderBalanceTable("Balance Sheet — Other", sec: sections.other)
                    }

                    // Summary check: Assets vs Equity + Liabilities
                    if let sum = sections.summary {
                        let ajk = sum.equity + sum.liabilities
                        let ok  = (sum.assets == ajk)

                        HTML.div(["class": "summary"]) {
                            HTML.text("Som Activa: \(fmt(sum.assets))")
                        }
                        HTML.div(["class": "summary"]) {
                            HTML.text("Som Eigen Vermogen + Passiva: \(fmt(ajk))")
                        }
                        HTML.div(["class": "summary"]) {
                            if ok {
                                HTML.text("")
                            } else {
                                HTML.span(["class": "warn"]) {
                                    HTML.text("DIFF: " + fmt(sum.assets - ajk))
                                }
                            }
                        }
                    }
                }
            }
        }

        // Pretty HTML with doctype via Constructors
        return doc.render(default: .pretty, doctype: true)
    }
}
