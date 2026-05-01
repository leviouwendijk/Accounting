import Accounting
import Foundation
import Terminal

public struct VATStatusTextOptions: Sendable {
    public var title: String
    public var showHeader: Bool
    public var showEntries: Bool
    public var onlyFlagged: Bool
    public var fractionDigits: Int?

    public init(
        title: String = "VAT status",
        showHeader: Bool = true,
        showEntries: Bool = true,
        onlyFlagged: Bool = false,
        fractionDigits: Int? = 2
    ) {
        self.title = title
        self.showHeader = showHeader
        self.showEntries = showEntries
        self.onlyFlagged = onlyFlagged
        self.fractionDigits = fractionDigits
    }

    public var underline: String {
        String(repeating: "─", count: title.count)
    }
}

public extension VATStatusReport {
    func renderText(
        _ opts: VATStatusTextOptions = .init()
    ) -> String {
        func fmtNumber(
            _ x: Decimal
        ) -> String {
            guard let digits = opts.fractionDigits else {
                return x.description
            }

            var value = x
            var rounded = Decimal()
            NSDecimalRound(&rounded, &value, digits, .plain)

            let formatter = NumberFormatter()
            formatter.locale = Locale(identifier: "nl_NL")
            formatter.numberStyle = .decimal
            formatter.minimumFractionDigits = digits
            formatter.maximumFractionDigits = digits

            let absolute = DecimalFuncs.absDec(rounded)

            let core = formatter.string(
                from: absolute as NSDecimalNumber
            ) ?? absolute.description

            if rounded < 0 {
                return "(\(core))"
            }

            return core
        }

        func fmt(
            _ x: Decimal
        ) -> String {
            let rendered = fmtNumber(x)

            if x > 0 {
                return rendered.ansi(.bold, .green)
            }

            if x < 0 {
                return rendered.ansi(.bold, .red)
            }

            return rendered
        }

        func fmtPlain(
            _ x: Decimal
        ) -> String {
            fmtNumber(x)
        }

        func quarterLabel(
            _ period: VATPeriod
        ) -> String {
            "\(period.year)Q\(period.quarter.rawValue)"
        }

        func dateLabel(
            _ date: Date
        ) -> String {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            formatter.dateFormat = "yyyy-MM-dd"
            return formatter.string(from: date)
        }

        func familyBreakdown(
            _ family: VATStatusFamily,
            in quarter: VATStatusQuarter
        ) -> VATStatusFamilyBreakdown? {
            quarter.ordinaryBreakdownTree.first {
                $0.family == family
            }
        }

        func padded(
            _ value: String,
            to width: Int
        ) -> String {
            if value.count >= width {
                return value
            }

            return value + String(repeating: " ", count: width - value.count)
        }

        func left(
            _ value: String,
            width: Int
        ) -> String {
            String(value.prefix(width)).padding(
                toLength: width,
                withPad: " ",
                startingAt: 0
            )
        }

        func right(
            _ value: String,
            width: Int
        ) -> String {
            if value.count >= width {
                return String(value.suffix(width))
            }

            return String(repeating: " ", count: width - value.count) + value
        }

        func wrapWords(
            _ text: String,
            width: Int
        ) -> [String] {
            guard width > 8 else {
                return [text]
            }

            var lines: [String] = []
            var current = ""

            for word in text.split(separator: " ") {
                let next = current.isEmpty
                    ? String(word)
                    : current + " " + word

                if next.count <= width {
                    current = next
                } else {
                    if !current.isEmpty {
                        lines.append(current)
                    }

                    current = String(word)
                }
            }

            if !current.isEmpty {
                lines.append(current)
            }

            return lines.isEmpty ? [""] : lines
        }

        func renderTreeNodes(
            _ nodes: [VATStatusTreeNode],
            indent: String,
            into out: inout [String]
        ) {
            let textWidth = 72

            for node in nodes {
                let label = "\(node.code) — \(node.label)"
                let wrapped = wrapWords(label, width: textWidth)

                if let first = wrapped.first {
                    out.append(
                        "\(indent)• \(first)"
                            + "  \(fmt(node.amount))"
                    )
                }

                for line in wrapped.dropFirst() {
                    out.append(
                        "\(indent)  \(line)"
                    )
                }

                if !node.children.isEmpty {
                    renderTreeNodes(
                        node.children,
                        indent: indent + "    ",
                        into: &out
                    )
                }
            }
        }

        func renderFilingBreakdown(
            _ rows: [VATStatusFilingRow],
            into out: inout [String]
        ) {
            guard !rows.isEmpty else {
                return
            }

            let labelWidth = 24
            let amountWidth = 13

            out.append("filing overview:")
            out.append(
                "  "
                    + left("rubriek / family", width: labelWidth)
                    + right("carry in", width: amountWidth)
                    + "  "
                    + right("period", width: amountWidth)
                    + "  "
                    + right("net", width: amountWidth)
            )

            out.append(
                "  "
                    + String(
                        repeating: "─",
                        count: labelWidth + amountWidth * 3 + 4
                    )
            )

            for row in rows {
                out.append(
                    "  "
                        + left(row.family.displayLabel, width: labelWidth)
                        + right(fmtPlain(row.carryIn), width: amountWidth)
                        + "  "
                        + right(fmtPlain(row.period), width: amountWidth)
                        + "  "
                        + right(fmtPlain(row.net), width: amountWidth)
                )
            }

            let totalCarry = rows.reduce(Decimal(0)) { $0 + $1.carryIn }
            let totalPeriod = rows.reduce(Decimal(0)) { $0 + $1.period }
            let totalNet = rows.reduce(Decimal(0)) { $0 + $1.net }

            out.append(
                "  "
                    + String(
                        repeating: "─",
                        count: labelWidth + amountWidth * 3 + 4
                    )
            )

            out.append(
                "  "
                    + left("total", width: labelWidth)
                    + right(fmtPlain(totalCarry), width: amountWidth)
                    + "  "
                    + right(fmtPlain(totalPeriod), width: amountWidth)
                    + "  "
                    + right(fmtPlain(totalNet), width: amountWidth)
            )
        }

        let rows = opts.onlyFlagged
            ? flaggedQuarters
            : quarters

        var out: [String] = []

        if opts.showHeader {
            out.append(opts.title)
            out.append(opts.underline)
        }

        out.append("Quarters: \(rows.count)")
        out.append("Flagged: \(rows.filter { DecimalFuncs.absDec($0.residual) > tolerance }.count)")
        out.append("Tolerance: \(fmt(tolerance))")
        out.append("Latest residual owed: \(fmt(latestDisplayResidualOwed))")
        out.append("Latest residual receivable: \(fmt(latestDisplayResidualReceivable))")

        for quarter in rows {
            out.append("")
            out.append(quarterLabel(quarter.period))
            out.append("──────")
            out.append("carry in:                 \(fmt(quarter.carryIn))")
            out.append("ordinary net:             \(fmt(quarter.ordinaryNet))")

            out.append("  output:                 \(fmt(quarter.outputNet))")
            if let breakdown = familyBreakdown(.output, in: quarter),
               !breakdown.nodes.isEmpty {
                renderTreeNodes(
                    breakdown.nodes,
                    indent: "    ",
                    into: &out
                )
            }

            out.append("  deductible:             \(fmt(quarter.deductibleNet))")
            if let breakdown = familyBreakdown(.deductible, in: quarter),
               !breakdown.nodes.isEmpty {
                renderTreeNodes(
                    breakdown.nodes,
                    indent: "    ",
                    into: &out
                )
            }

            out.append("  private use:            \(fmt(quarter.privateUseNet))")
            if let breakdown = familyBreakdown(.privateUse, in: quarter),
               !breakdown.nodes.isEmpty {
                renderTreeNodes(
                    breakdown.nodes,
                    indent: "    ",
                    into: &out
                )
            }

            out.append("  receivable:             \(fmt(quarter.receivableNet))")
            if let breakdown = familyBreakdown(.receivable, in: quarter),
               !breakdown.nodes.isEmpty {
                renderTreeNodes(
                    breakdown.nodes,
                    indent: "    ",
                    into: &out
                )
            }

            out.append("  payable fallback:       \(fmt(quarter.payableFallbackNet))")
            if let breakdown = familyBreakdown(.payableFallback, in: quarter),
               !breakdown.nodes.isEmpty {
                renderTreeNodes(
                    breakdown.nodes,
                    indent: "    ",
                    into: &out
                )
            }

            renderFilingBreakdown(
                quarter.filingBreakdown,
                into: &out
            )

            out.append("corrections net:          \(fmt(quarter.correctionsNet))")
            out.append("expected before settle:   \(fmt(quarter.expectedSettlementNet))")
            out.append("paid:                     \(fmt(quarter.paid))")
            out.append("received:                 \(fmt(quarter.received))")
            out.append("settlement net:           \(fmt(quarter.settlementNet))")
            out.append("residual:                 \(fmt(quarter.residual))")
            out.append("residual owed:            \(fmt(quarter.displayResidualOwed))")
            out.append("residual receivable:      \(fmt(quarter.displayResidualReceivable))")

            if quarter.residualContributions.isEmpty {
                out.append("residual sources: none")
            } else {
                out.append("residual sources:")

                for item in quarter.residualContributions {
                    out.append(
                        "  • \(quarterLabel(item.sourcePeriod))  \(fmt(item.amount))"
                    )
                }
            }

            if opts.showEntries {
                if quarter.entries.isEmpty {
                    out.append("entries: none")
                } else {
                    out.append("entries:")

                    for entry in quarter.entries {
                        let idLabel = entry.entryId.map { "[entry \($0)]" } ?? ""
                        out.append(
                            "  • \(entry.displayKind)  \(fmt(entry.netAmount))  \(dateLabel(entry.postingDate))  \(idLabel)"
                        )

                        if !entry.vatAccountCodes.isEmpty {
                            out.append(
                                "    codes: \(entry.vatAccountCodes.joined(separator: ", "))"
                            )
                        }

                        if let details = entry.details,
                           !details.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            out.append("    details:")
                            for line in details.split(separator: "\n", omittingEmptySubsequences: false) {
                                out.append("        \(line)")
                            }
                        }
                    }
                }
            }
        }

        return out.joined(separator: "\n")
    }
}
