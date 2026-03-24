import Foundation

public enum AssetsOverviewPrinter {
    public static func renderText(
        _ overview: AssetsOverview,
        diagnostics: Bool = false
    ) -> String {
        var lines: [String] = []

        let title = "Assets overview"
        lines.append(title)
        lines.append(String(repeating: "─", count: title.count))
        lines.append("Period: \(overview.period.string())")
        lines.append("Assets inspected: \(overview.summary.assetCount)")
        lines.append("Flagged assets: \(overview.summary.flaggedAssetCount)")
        lines.append("")

        lines.append("Acquisition cost total: \(fmt(overview.summary.acquisitionCostTotal))")
        lines.append("Opening carrying amount total: \(fmt(overview.summary.openingCarryingAmountTotal))")
        lines.append("Investments in period: \(fmt(overview.summary.periodInvestmentTotal))")
        lines.append("Depreciation in period: \(fmt(overview.summary.periodDepreciationTotal))")
        lines.append("Closing carrying amount total: \(fmt(overview.summary.closingCarryingAmountTotal))")

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
            lines.append(group.name)
            lines.append(String(repeating: "─", count: max(group.name.count, 8)))

            for row in group.rows {
                lines.append(row.displayName)
                lines.append("    Key: \(row.entityKey.identifier(displaying: .fullchain))")

                if let details = row.details {
                    lines.append("    Details: \(details)")
                } else if diagnostics {
                    lines.append("    Details: —")
                }

                if let type = row.type {
                    lines.append("    Type: \(type)")
                } else if diagnostics {
                    lines.append("    Type: —")
                }

                if let acquisitionDate = row.acquisitionDate {
                    lines.append("    Acquisition date: \(fmtDate(acquisitionDate))")
                } else if diagnostics {
                    lines.append("    Acquisition date: —")
                }

                if let commissionDate = row.commissionDate {
                    lines.append("    Commission date: \(fmtDate(commissionDate))")
                } else if diagnostics {
                    lines.append("    Commission date: —")
                }

                if let acquisitionCost = row.acquisitionCost {
                    lines.append("    Acquisition cost: \(fmt(acquisitionCost))")
                } else if diagnostics {
                    lines.append("    Acquisition cost: —")
                }

                if let usefulLifeYears = row.usefulLifeYears {
                    lines.append("    Useful life: \(fmt(usefulLifeYears)) years")
                } else if diagnostics {
                    lines.append("    Useful life: —")
                }

                if let residualPercentage = row.residualPercentage,
                   let residualAmount = row.residualAmount
                {
                    lines.append(
                        "    Residual: \(fmtPct(residualPercentage)) → \(fmt(residualAmount))"
                    )
                } else if diagnostics {
                    lines.append("    Residual: —")
                }

                if let depreciationAccountCode = row.depreciationAccountCode {
                    lines.append("    Depreciation account: \(depreciationAccountCode)")
                } else if diagnostics {
                    lines.append("    Depreciation account: —")
                }

                if let contraAccountCode = row.contraAccountCode {
                    lines.append("    Contra account: \(contraAccountCode)")
                } else if diagnostics {
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
                } else if diagnostics {
                    lines.append("    Shares: —")
                }

                if row.flags.isEmpty {
                    if diagnostics {
                        lines.append("    Flags: none")
                    }
                } else {
                    lines.append("    Flags: \(row.flags.joined(separator: "; "))")
                }

                lines.append("")
            }
        }

        while lines.last == "" {
            lines.removeLast()
        }

        return lines.joined(separator: "\n")
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
