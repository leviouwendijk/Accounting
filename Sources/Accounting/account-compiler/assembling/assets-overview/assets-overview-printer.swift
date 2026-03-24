import Foundation

public enum AssetsOverviewPrinter {
    public static func renderText(
        _ overview: AssetsOverview,
        diagnostics: Bool = false
    ) -> String {
        var lines: [String] = []

        let title = "Assets filing overview"
        lines.append(title)
        lines.append(String(repeating: "─", count: title.count))
        lines.append("Period: \(overview.period.string())")
        lines.append("Assets inspected: \(overview.summary.assetCount)")
        lines.append("Flagged assets: \(overview.summary.flaggedAssetCount)")

        if overview.summary.unclassifiedNonZeroAssetCount > 0 {
            lines.append("")
            lines.append("Warning")
            lines.append("───────")
            lines.append("Unclassified non-zero assets: \(overview.summary.unclassifiedNonZeroAssetCount)")
            lines.append("Unclassified acquisition cost total: \(fmt(overview.summary.unclassifiedNonZeroTotals.acquisitionCost))")
            lines.append("Unclassified opening carrying amount total: \(fmt(overview.summary.unclassifiedNonZeroTotals.openingCarryingAmount))")
            lines.append("Unclassified investments in period: \(fmt(overview.summary.unclassifiedNonZeroTotals.periodInvestment))")
            lines.append("Unclassified depreciation in period: \(fmt(overview.summary.unclassifiedNonZeroTotals.periodDepreciation))")
            lines.append("Unclassified closing carrying amount total: \(fmt(overview.summary.unclassifiedNonZeroTotals.closingCarryingAmount))")
            lines.append("Unclassified residual amount total: \(fmt(overview.summary.unclassifiedNonZeroTotals.residualAmount))")
        }

        if diagnostics && !overview.diagnosticCounts.isEmpty {
            lines.append("")
            lines.append("Diagnostics")
            lines.append("───────────")

            for pair in overview.diagnosticCounts.sorted(by: diagnosticSort) {
                lines.append("• \(pair.key): \(pair.value)")
            }
        }

        for group in overview.groups {
            lines.append("")
            render(
                section: group,
                diagnostics: diagnostics,
                into: &lines
            )
        }

        while lines.last == "" {
            lines.removeLast()
        }

        return lines.joined(separator: "\n")
    }

    private static func render(
        section group: AssetsOverviewGroup,
        diagnostics: Bool,
        into lines: inout [String]
    ) {
        lines.append(group.name)
        lines.append(String(repeating: "─", count: max(group.name.count, 8)))

        switch group.section {
        case .tangibleFixedAssets:
            lines.append("Kosten van aanschaf of voortbrenging | Boekwaarde begin boekjaar | Boekwaarde einde boekjaar | Restwaarde")

            for line in group.lines {
                appendTangibleFixedAssetsLine(
                    name: line.name,
                    totals: line.totals,
                    into: &lines
                )
            }

            appendTangibleFixedAssetsLine(
                name: group.totalLabel,
                totals: group.totals,
                into: &lines
            )

        case .inventory:
            lines.append("Boekwaarde begin boekjaar | Boekwaarde einde boekjaar")

            for line in group.lines {
                appendTwoColumnLine(
                    name: line.name,
                    first: line.totals.openingCarryingAmount,
                    second: line.totals.closingCarryingAmount,
                    into: &lines
                )
            }

            appendTwoColumnLine(
                name: group.totalLabel,
                first: group.totals.openingCarryingAmount,
                second: group.totals.closingCarryingAmount,
                into: &lines
            )

        case .receivables:
            lines.append("Nominale waarde | Boekwaarde begin boekjaar | Boekwaarde einde boekjaar")

            for line in group.lines {
                appendThreeColumnLine(
                    name: line.name,
                    first: line.totals.acquisitionCost,
                    second: line.totals.openingCarryingAmount,
                    third: line.totals.closingCarryingAmount,
                    into: &lines
                )
            }

            appendThreeColumnLine(
                name: group.totalLabel,
                first: group.totals.acquisitionCost,
                second: group.totals.openingCarryingAmount,
                third: group.totals.closingCarryingAmount,
                into: &lines
            )

            if let vatLine = group.lines.first(where: { $0.category == .vat_receivable }) {
                lines.append("")
                lines.append("Specificatie vordering omzetbelasting")
                lines.append("Vordering omzetbelasting over het vorige boekjaar | Totaal boekwaarde omzetbelasting")
                appendTwoColumnLine(
                    name: vatLine.name,
                    first: vatLine.totals.openingCarryingAmount,
                    second: vatLine.totals.closingCarryingAmount,
                    into: &lines
                )
            }

        case .liquidAssets:
            lines.append("Boekwaarde begin boekjaar | Boekwaarde einde boekjaar")

            for line in group.lines {
                appendTwoColumnLine(
                    name: line.name,
                    first: line.totals.openingCarryingAmount,
                    second: line.totals.closingCarryingAmount,
                    into: &lines
                )
            }

            appendTwoColumnLine(
                name: group.totalLabel,
                first: group.totals.openingCarryingAmount,
                second: group.totals.closingCarryingAmount,
                into: &lines
            )

        case .unclassified:
            lines.append("Kosten / nominale waarde | Boekwaarde begin boekjaar | Boekwaarde einde boekjaar | Restwaarde")

            for line in group.lines {
                appendFourColumnLine(
                    name: line.name,
                    first: line.totals.acquisitionCost,
                    second: line.totals.openingCarryingAmount,
                    third: line.totals.closingCarryingAmount,
                    fourth: line.totals.residualAmount,
                    into: &lines
                )
            }

            appendFourColumnLine(
                name: group.totalLabel,
                first: group.totals.acquisitionCost,
                second: group.totals.openingCarryingAmount,
                third: group.totals.closingCarryingAmount,
                fourth: group.totals.residualAmount,
                into: &lines
            )
        }

        if diagnostics {
            for line in group.lines {
                lines.append("")
                lines.append("Underlying assets — \(line.name)")
                lines.append(String(repeating: "·", count: max(18, line.name.count + 20)))

                for row in line.rows {
                    renderDiagnosticRow(
                        row,
                        into: &lines
                    )
                    lines.append("")
                }

                if lines.last == "" {
                    lines.removeLast()
                }
            }
        }
    }

    private static func appendTangibleFixedAssetsLine(
        name: String,
        totals: AssetsOverviewAmounts,
        into lines: inout [String]
    ) {
        lines.append(
            "\(name) | \(fmt(totals.acquisitionCost)) | \(fmt(totals.openingCarryingAmount)) | \(fmt(totals.closingCarryingAmount)) | \(fmt(totals.residualAmount))"
        )
    }

    private static func appendTwoColumnLine(
        name: String,
        first: Decimal,
        second: Decimal,
        into lines: inout [String]
    ) {
        lines.append(
            "\(name) | \(fmt(first)) | \(fmt(second))"
        )
    }

    private static func appendThreeColumnLine(
        name: String,
        first: Decimal,
        second: Decimal,
        third: Decimal,
        into lines: inout [String]
    ) {
        lines.append(
            "\(name) | \(fmt(first)) | \(fmt(second)) | \(fmt(third))"
        )
    }

    private static func appendFourColumnLine(
        name: String,
        first: Decimal,
        second: Decimal,
        third: Decimal,
        fourth: Decimal,
        into lines: inout [String]
    ) {
        lines.append(
            "\(name) | \(fmt(first)) | \(fmt(second)) | \(fmt(third)) | \(fmt(fourth))"
        )
    }

    private static func renderDiagnosticRow(
        _ row: AssetsOverviewRow,
        into lines: inout [String]
    ) {
        lines.append(row.displayName)
        lines.append("    Key: \(row.entityKey.identifier(displaying: .fullchain))")

        if let details = row.details {
            lines.append("    Details: \(details)")
        } else {
            lines.append("    Details: —")
        }

        if let type = row.type {
            lines.append("    Type: \(type)")
        } else {
            lines.append("    Type: —")
        }

        if let acquisitionDate = row.acquisitionDate {
            lines.append("    Acquisition date: \(fmtDate(acquisitionDate))")
        } else {
            lines.append("    Acquisition date: —")
        }

        if let commissionDate = row.commissionDate {
            lines.append("    Commission date: \(fmtDate(commissionDate))")
        } else {
            lines.append("    Commission date: —")
        }

        if let acquisitionCost = row.acquisitionCost {
            lines.append("    Acquisition cost: \(fmt(acquisitionCost))")
        } else {
            lines.append("    Acquisition cost: —")
        }

        if let usefulLifeYears = row.usefulLifeYears {
            lines.append("    Useful life: \(fmt(usefulLifeYears)) years")
        } else {
            lines.append("    Useful life: —")
        }

        if let residualPercentage = row.residualPercentage,
           let residualAmount = row.residualAmount
        {
            lines.append("    Residual: \(fmtPct(residualPercentage)) → \(fmt(residualAmount))")
        } else {
            lines.append("    Residual: —")
        }

        if let depreciationAccountCode = row.depreciationAccountCode {
            lines.append("    Depreciation account: \(depreciationAccountCode)")
        } else {
            lines.append("    Depreciation account: —")
        }

        if let contraAccountCode = row.contraAccountCode {
            lines.append("    Contra account: \(contraAccountCode)")
        } else {
            lines.append("    Contra account: —")
        }

        lines.append("    Opening carrying amount: \(fmt(row.openingCarryingAmount))")
        lines.append("    Investments in period: \(fmt(row.periodInvestment))")
        lines.append("    Depreciation in period: \(fmt(row.periodDepreciation))")
        lines.append("    Closing carrying amount: \(fmt(row.closingCarryingAmount))")

        if !row.ownerShares.isEmpty {
            lines.append("    Shares:")

            for share in row.ownerShares {
                lines.append(
                    "        - \(share.ownerLabel): \(fmtPct(share.percentage)) → \(fmt(share.amount))"
                )
            }
        } else {
            lines.append("    Shares: —")
        }

        if row.flags.isEmpty {
            lines.append("    Flags: none")
        } else {
            lines.append("    Flags: \(row.flags.joined(separator: "; "))")
        }
    }

    private static func diagnosticSort(
        lhs: (key: String, value: Int),
        rhs: (key: String, value: Int)
    ) -> Bool {
        if lhs.value != rhs.value {
            return lhs.value > rhs.value
        }

        return lhs.key.localizedCaseInsensitiveCompare(rhs.key) == .orderedAscending
    }

    private static func fmt(
        _ value: Decimal,
        digits: Int = 2
    ) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "nl_NL")
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = digits
        formatter.maximumFractionDigits = digits

        return formatter.string(from: value as NSDecimalNumber)
            ?? value.description
    }

    private static func fmtPct(
        _ value: Decimal,
        digits: Int = 2
    ) -> String {
        "\(fmt(value, digits: digits))%"
    }

    private static func fmtDate(
        _ date: Date
    ) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
