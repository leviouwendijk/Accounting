import Accounting
import Foundation
import Terminal

public struct VATFilingTextOptions: Sendable {
    public var title: String
    public var showSourceRows: Bool
    public var showCarryDetail: Bool
    public var fractionDigits: Int
    public var width: Int?

    public init(
        title: String = "VAT filing",
        showSourceRows: Bool = true,
        showCarryDetail: Bool = false,
        fractionDigits: Int = 2,
        width: Int? = nil
    ) {
        self.title = title
        self.showSourceRows = showSourceRows
        self.showCarryDetail = showCarryDetail
        self.fractionDigits = fractionDigits
        self.width = width
    }
}

public extension VATFilingReport {
    func renderText(
        _ options: VATFilingTextOptions = .init()
    ) -> String {
        let detectedWidth = Terminal.size(
            for: .standardOutput
        ).columns

        let width = max(
            78,
            min(
                112,
                options.width ?? detectedWidth
            )
        )

        let codeWidth = 18
        let amountWidth = 13
        let turnoverWidth = 13
        let vatWidth = 13
        let tableSpacing = 2
        let tableGapWidth = tableSpacing * 3

        let vatLabelWidth = max(
            26,
            width
                - codeWidth
                - turnoverWidth
                - vatWidth
                - tableGapWidth
        )

        let sourceLabelWidth = max(
            26,
            width
                - codeWidth
                - amountWidth
                - tableSpacing * 2
                - 4
        )

        func fmt(
            _ x: Decimal?
        ) -> String {
            guard let x else {
                return "—"
            }

            var value = x
            var rounded = Decimal()

            NSDecimalRound(
                &rounded,
                &value,
                options.fractionDigits,
                .plain
            )

            let formatter = NumberFormatter()
            formatter.locale = Locale(identifier: "nl_NL")
            formatter.numberStyle = .decimal
            formatter.minimumFractionDigits = options.fractionDigits
            formatter.maximumFractionDigits = options.fractionDigits

            let absolute = DecimalFuncs.absDec(
                rounded
            )

            let rendered = formatter.string(
                from: absolute as NSDecimalNumber
            ) ?? absolute.description

            if rounded < 0 {
                return "(\(rendered))"
            }

            return rendered
        }

        func pad(
            _ value: String,
            _ width: Int
        ) -> String {
            if value.count >= width {
                return value
            }

            return value + String(
                repeating: " ",
                count: width - value.count
            )
        }

        func lpad(
            _ value: String,
            _ width: Int
        ) -> String {
            if value.count >= width {
                return value
            }

            return String(
                repeating: " ",
                count: width - value.count
            ) + value
        }

        func blank(
            _ width: Int
        ) -> String {
            String(
                repeating: " ",
                count: width
            )
        }

        func divider(
            _ width: Int
        ) -> String {
            String(
                repeating: "─",
                count: width
            )
        }

        func periodLabel(
            _ period: VATPeriod
        ) -> String {
            "\(period.year)Q\(period.quarter.rawValue)"
        }

        func carryKindLabel(
            _ row: VATFilingCarryRow
        ) -> String {
            if row.isSettlementRemainder {
                return "settlement remainder"
            }

            if row.isFileableRubricCarry {
                return "rubric carry"
            }

            return "balance carry"
        }

        func wrapped(
            _ value: String,
            width: Int
        ) -> [String] {
            TerminalTextWrap.lines(
                value,
                width: width
            )
        }

        func appendWrappedVATRow(
            label: String,
            code: String,
            turnover: Decimal?,
            vat: Decimal,
            to out: inout [String]
        ) {
            let labelLines = wrapped(
                label,
                width: vatLabelWidth
            )

            let first = labelLines.first ?? ""

            out.append(
                pad(first, vatLabelWidth)
                    + String(repeating: " ", count: tableSpacing)
                    + pad(code, codeWidth)
                    + String(repeating: " ", count: tableSpacing)
                    + lpad(fmt(turnover), turnoverWidth)
                    + String(repeating: " ", count: tableSpacing)
                    + lpad(fmt(vat), vatWidth)
            )

            for line in labelLines.dropFirst() {
                out.append(
                    pad(line, vatLabelWidth)
                        + String(repeating: " ", count: tableSpacing)
                        + blank(codeWidth)
                        + String(repeating: " ", count: tableSpacing)
                        + blank(turnoverWidth)
                        + String(repeating: " ", count: tableSpacing)
                        + blank(vatWidth)
                )
            }
        }

        func appendWrappedSourceRow(
            _ row: VATFilingSourceRow,
            indent: String,
            to out: inout [String]
        ) {
            let bullet = indent + "• "
            let continuationPrefix = indent + "  "

            let labelLines = wrapped(
                row.label,
                width: sourceLabelWidth
            )

            let first = labelLines.first ?? ""

            out.append(
                bullet
                    + pad(first, sourceLabelWidth)
                    + String(repeating: " ", count: tableSpacing)
                    + pad(row.code, codeWidth)
                    + String(repeating: " ", count: tableSpacing)
                    + lpad(fmt(row.amount), amountWidth)
            )

            for line in labelLines.dropFirst() {
                out.append(
                    continuationPrefix
                        + pad(line, sourceLabelWidth)
                        + String(repeating: " ", count: tableSpacing)
                        + blank(codeWidth)
                        + String(repeating: " ", count: tableSpacing)
                        + blank(amountWidth)
                )
            }

            guard !row.entryIDs.isEmpty else {
                return
            }

            let entryText = "entries: "
                + row.entryIDs
                    .map(String.init)
                    .joined(separator: ", ")

            for line in wrapped(
                entryText,
                width: max(
                    20,
                    width - continuationPrefix.count
                )
            ) {
                out.append(
                    continuationPrefix + line
                )
            }
        }

        var out: [String] = []

        out.append(options.title)
        out.append(divider(options.title.count))
        out.append("Period: \(periodLabel(period))")

        if !warnings.isEmpty {
            out.append("")
            out.append("Warnings")
            out.append("────────")

            for warning in warnings {
                for line in wrapped(
                    warning,
                    width: max(20, width - 2)
                ) {
                    out.append("! \(line)")
                }
            }
        }

        func appendWrappedFilingBalanceRow(
            _ row: VATFilingBalanceRow,
            to out: inout [String]
        ) {
            let currentWidth = 13
            let carryWidth = 13
            let filingWidth = 13
            let localSpacing = 2
            let localGapWidth = localSpacing * 4

            let labelWidth = max(
                24,
                width
                    - codeWidth
                    - currentWidth
                    - carryWidth
                    - filingWidth
                    - localGapWidth
            )

            let labelLines = wrapped(
                row.label,
                width: labelWidth
            )

            let firstLabel = labelLines.first ?? ""

            out.append(
                pad(firstLabel, labelWidth)
                    + String(repeating: " ", count: localSpacing)
                    + pad(row.code, codeWidth)
                    + String(repeating: " ", count: localSpacing)
                    + lpad(fmt(row.currentVAT), currentWidth)
                    + String(repeating: " ", count: localSpacing)
                    + lpad(fmt(row.carryVAT), carryWidth)
                    + String(repeating: " ", count: localSpacing)
                    + lpad(fmt(row.filingVAT), filingWidth)
            )

            for extra in labelLines.dropFirst() {
                out.append(
                    pad(extra, labelWidth)
                )
            }
        }

        out.append("")
        out.append("Turnover")
        out.append("────────")

        if turnoverRows.isEmpty {
            out.append("none")
        } else {
            for row in turnoverRows {
                appendWrappedSourceRow(
                    row,
                    indent: "  ",
                    to: &out
                )
            }

            let total = turnoverRows.reduce(Decimal(0)) {
                $0 + $1.amount
            }

            out.append("  " + divider(max(1, width - 2)))
            out.append(
                "  "
                    + pad(
                        "total turnover",
                        max(
                            1,
                            width - amountWidth - 4
                        )
                    )
                    + lpad(fmt(total), amountWidth)
            )
        }

        out.append("")
        out.append("VAT filing rows")
        out.append("───────────────")
        out.append(
            pad("RGS label", vatLabelWidth)
                + String(repeating: " ", count: tableSpacing)
                + pad("RGS code", codeWidth)
                + String(repeating: " ", count: tableSpacing)
                + lpad("turnover", turnoverWidth)
                + String(repeating: " ", count: tableSpacing)
                + lpad("VAT", vatWidth)
        )
        out.append(divider(width))

        if vatRows.isEmpty {
            out.append("none")
        } else {
            for row in vatRows {
                appendWrappedVATRow(
                    label: row.label,
                    code: row.code,
                    turnover: row.turnover,
                    vat: row.vat,
                    to: &out
                )

                if options.showSourceRows {
                    for source in row.sourceRows where source.code != row.code {
                        appendWrappedSourceRow(
                            source,
                            indent: "    ",
                            to: &out
                        )
                    }
                }
            }
        }

        if !otherVATRows.isEmpty {
            out.append("")
            out.append("Other VAT accounts included")
            out.append("───────────────────────────")

            for row in otherVATRows {
                appendWrappedVATRow(
                    label: row.label,
                    code: row.code,
                    turnover: nil,
                    vat: row.vat,
                    to: &out
                )
            }
        }

        if !filingBalanceRows.isEmpty {
            out.append("")
            out.append("Filable VAT balances")
            out.append("────────────────────")
            out.append(
                pad("RGS label", max(24, width - codeWidth - 13 - 13 - 13 - 8))
                    + "  "
                    + pad("RGS code", codeWidth)
                    + "  "
                    + lpad("current", 13)
                    + "  "
                    + lpad("carry-in", 13)
                    + "  "
                    + lpad("filing", 13)
            )
            out.append(divider(width))

            for row in filingBalanceRows {
                appendWrappedFilingBalanceRow(
                    row,
                    to: &out
                )
            }

            let currentRaw = filingBalanceRows.reduce(Decimal(0)) {
                $0 + $1.currentRaw
            }

            let carryRaw = filingBalanceRows.reduce(Decimal(0)) {
                $0 + $1.carryRaw
            }

            let filingRaw = filingBalanceRows.reduce(Decimal(0)) {
                $0 + $1.filingRaw
            }

            out.append("")
            out.append("net current:                  \(fmt(currentRaw))")
            out.append("net carry-in:                 \(fmt(carryRaw))")
            out.append("net filing balance:           \(fmt(filingRaw))")
        }

        if options.showCarryDetail && !carryRows.isEmpty {
            out.append("")
            out.append("Carry-in detail")
            out.append("───────────────")
            out.append(
                pad("source", 8)
                    + "  "
                    + pad("kind", 20)
                    + "  "
                    + pad("RGS code", 18)
                    + "  "
                    + lpad("amount", 13)
                    + "  "
                    + "entry"
            )
            out.append(divider(width))

            for row in carryRows {
                let entryLabel = row.entryId.map {
                    String($0)
                } ?? "—"

                out.append(
                    pad(periodLabel(row.sourcePeriod), 8)
                        + "  "
                        + pad(carryKindLabel(row), 20)
                        + "  "
                        + pad(row.code, 18)
                        + "  "
                        + lpad(fmt(row.amount), 13)
                        + "  "
                        + entryLabel
                )

                let detail = row.label

                for line in wrapped(
                    detail,
                    width: max(20, width - 4)
                ) {
                    out.append("    " + line)
                }
            }

            let fileable = carryRows
                .filter(\.isFileableRubricCarry)
                .reduce(Decimal(0)) {
                    $0 + $1.amount
                }

            let settlement = carryRows
                .filter(\.isSettlementRemainder)
                .reduce(Decimal(0)) {
                    $0 + $1.amount
                }

            out.append("")
            out.append("carry-in total:              \(fmt(reconciliation.carryIn))")
            out.append("fileable rubric carry:       \(fmt(fileable))")
            out.append("settlement/payment residue:  \(fmt(settlement))")
        }

        out.append("")
        out.append("Reconciliation")
        out.append("──────────────")
        out.append("current return payable:       \(fmt(reconciliation.currentPayable))")
        out.append("current return receivable:    \(fmt(reconciliation.currentReceivable))")
        out.append("carry in:                     \(fmt(reconciliation.carryIn))")
        out.append("expected payable to clear:    \(fmt(reconciliation.expectedPayable))")
        out.append("expected receivable to clear: \(fmt(reconciliation.expectedReceivable))")

        if let balanceSheetNetPosition = reconciliation.balanceSheetNetPosition {
            out.append("balance-sheet VAT position:   \(fmt(balanceSheetNetPosition))")
        }

        if let statusDifference = reconciliation.statusDifference {
            out.append("overview/status difference:   \(fmt(statusDifference))")
        }

        out.append("")
        out.append("Coverage check")
        out.append("──────────────")
        out.append("included VAT root movement:   \(fmt(reconciliation.includedVATRaw))")
        out.append("all VAT root movement:        \(fmt(reconciliation.allVATRootRaw))")
        out.append("difference:                   \(fmt(reconciliation.unclassifiedDifference))")

        return out.joined(separator: "\n")
    }
}
