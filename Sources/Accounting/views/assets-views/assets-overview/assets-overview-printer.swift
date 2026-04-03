import Foundation

extension AssetViews {
    public enum AssetsOverviewPrinter {
        public static func renderText(
            _ overview: AssetsOverview,
            diagnostics: Bool = false
        ) -> String {
            renderText(
                overview,
                options: .init(
                    diagnostics: diagnostics,
                    showUnderlyingRows: true,
                    showOnlyFlaggedUnderlyingRows: false,
                    showZeroUnderlyingRows: false,
                    diagnosticsOnlyForFlaggedRows: true
                )
            )
        }

        public static func renderText(
            _ overview: AssetsOverview,
            options: AssetsOverviewRenderOptions
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

                for row in overview.summary.unclassifiedNonZeroRows {
                    lines.append("    · \(row.displayName) (\(row.entityKey.identifier(displaying: .fullchain)))")
                }
            }

            if options.diagnostics && !overview.diagnosticCounts.isEmpty {
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
                    options: options,
                    into: &lines
                )
            }

            if !overview.groups.isEmpty {
                let shareSummary = AssetViews.AssetsOverviewSharesSummary.visible(
                    from: overview
                )

                lines.append("")
                lines.append("Totaal activa")
                lines.append("────────────")
                lines.append("Boekwaarde begin boekjaar | \(fmt(totalOpeningAcrossVisibleSections(overview)))")
                lines.append("Boekwaarde einde boekjaar | \(fmt(totalClosingAcrossVisibleSections(overview)))")

                lines.append("")
                lines.append("Aandelen in activa (vermogenschatting)")
                lines.append("────────────────────────────────────")
                lines.append("Som activa-aandelen begin boekjaar | \(fmt(shareSummary.openingCarryingAmount))")
                appendShareBreakdown(
                    shareSummary.breakdown,
                    value: \.openingCarryingAmount,
                    into: &lines
                )

                lines.append("Som activa-aandelen investeringen in periode | \(fmt(shareSummary.periodInvestment))")
                appendShareBreakdown(
                    shareSummary.breakdown,
                    value: \.periodInvestment,
                    into: &lines
                )

                lines.append("Som activa-aandelen einde boekjaar | \(fmt(shareSummary.closingCarryingAmount))")
                appendShareBreakdown(
                    shareSummary.breakdown,
                    value: \.closingCarryingAmount,
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
            options: AssetsOverviewRenderOptions,
            into lines: inout [String]
        ) {
            lines.append(group.name)
            lines.append(String(repeating: "─", count: max(group.name.count, 8)))

            let columnProfile = AssetsOverviewColumnProfile.forSection(group.section)
            lines.append(columnProfile.headers.joined(separator: " | "))

            for line in group.lines {
                appendLine(
                    name: line.name,
                    totals: line.totals,
                    profile: columnProfile,
                    into: &lines
                )

                if options.showUnderlyingRows {
                    let filteredRows = line.rows.filter { row in
                        if options.showOnlyFlaggedUnderlyingRows && !row.hasIssues {
                            return false
                        }

                        if !options.showZeroUnderlyingRows && !hasVisibleUnderlyingAmounts(row) {
                            return false
                        }

                        return true
                    }

                    for row in filteredRows {
                        renderUnderlyingRow(
                            row,
                            profile: columnProfile,
                            into: &lines
                        )
                    }
                }
            }

            appendLine(
                name: group.totalLabel,
                totals: group.totals,
                profile: columnProfile,
                into: &lines
            )

            if group.section == .receivables {
                renderVATSpecification(
                    from: group,
                    into: &lines
                )
            }

            if options.diagnostics {
                let diagnosticLines = group.lines.filter { line in
                    let rows = line.rows.filter { row in
                        if options.diagnosticsOnlyForFlaggedRows {
                            return row.hasIssues
                        }

                        return true
                    }

                    return !rows.isEmpty
                }

                for line in diagnosticLines {
                    lines.append("")
                    lines.append("Underlying assets — \(line.name)")
                    lines.append(String(repeating: "·", count: max(18, line.name.count + 20)))

                    let rows = line.rows.filter { row in
                        if options.diagnosticsOnlyForFlaggedRows {
                            return row.hasIssues
                        }

                        return true
                    }

                    for row in rows {
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

        private static func appendLine(
            name: String,
            totals: AssetsOverviewAmounts,
            profile: AssetsOverviewColumnProfile,
            into lines: inout [String]
        ) {
            switch profile {
            case .intangibleFixedAssets:
                lines.append(
                    "\(name) | \(fmt(totals.acquisitionCost)) | \(fmt(totals.openingCarryingAmount)) | \(fmt(totals.closingCarryingAmount)) | \(fmt(totals.residualAmount))"
                )

            case .tangibleFixedAssets:
                lines.append(
                    "\(name) | \(fmt(totals.acquisitionCost)) | \(fmt(totals.openingCarryingAmount)) | \(fmt(totals.closingCarryingAmount)) | \(fmt(totals.residualAmount))"
                )

            case .financialFixedAssets, .inventory, .securities, .liquidAssets:
                lines.append(
                    "\(name) | \(fmt(totals.openingCarryingAmount)) | \(fmt(totals.closingCarryingAmount))"
                )

            case .receivables:
                lines.append(
                    "\(name) | \(fmt(totals.acquisitionCost)) | \(fmt(totals.openingCarryingAmount)) | \(fmt(totals.closingCarryingAmount))"
                )

            case .unclassified:
                lines.append(
                    "\(name) | \(fmt(totals.acquisitionCost)) | \(fmt(totals.openingCarryingAmount)) | \(fmt(totals.closingCarryingAmount)) | \(fmt(totals.residualAmount))"
                )
            }
        }

        private static func renderUnderlyingRow(
            _ row: AssetsOverviewRow,
            profile: AssetsOverviewColumnProfile,
            into lines: inout [String]
        ) {
            let marker = issueMarker(for: row)
            let label = "    · \(row.displayName)\(marker.isEmpty ? "" : " \(marker)")"

            switch profile {
            case .intangibleFixedAssets:
                lines.append(
                    "\(label) | \(fmt(row.acquisitionCost ?? 0)) | \(fmt(row.openingCarryingAmount)) | \(fmt(row.closingCarryingAmount)) | \(fmt(row.residualAmount ?? 0))"
                )

            case .tangibleFixedAssets:
                lines.append(
                    "\(label) | \(fmt(row.acquisitionCost ?? 0)) | \(fmt(row.openingCarryingAmount)) | \(fmt(row.closingCarryingAmount)) | \(fmt(row.residualAmount ?? 0))"
                )

            case .financialFixedAssets, .inventory, .securities, .liquidAssets:
                lines.append(
                    "\(label) | \(fmt(row.openingCarryingAmount)) | \(fmt(row.closingCarryingAmount))"
                )

            case .receivables:
                lines.append(
                    "\(label) | \(fmt(row.acquisitionCost ?? 0)) | \(fmt(row.openingCarryingAmount)) | \(fmt(row.closingCarryingAmount))"
                )

            case .unclassified:
                lines.append(
                    "\(label) | \(fmt(row.acquisitionCost ?? 0)) | \(fmt(row.openingCarryingAmount)) | \(fmt(row.closingCarryingAmount)) | \(fmt(row.residualAmount ?? 0))"
                )
            }
        }

        // private static func appendLine(
        //     name: String,
        //     totals: AssetsOverviewAmounts,
        //     profile: AssetsOverviewColumnProfile,
        //     into lines: inout [String]
        // ) {
        //     switch profile {
        //     case .intangibleFixedAssets:
        //         lines.append(
        //             "\(name) | \(fmt(totals.acquisitionCost)) | \(fmt(totals.openingCarryingAmount)) | \(fmt(totals.closingCarryingAmount))"
        //         )

        //     case .tangibleFixedAssets:
        //         lines.append(
        //             "\(name) | \(fmt(totals.acquisitionCost)) | \(fmt(totals.openingCarryingAmount)) | \(fmt(totals.closingCarryingAmount)) | \(fmt(totals.residualAmount))"
        //         )

        //     case .financialFixedAssets, .inventory, .securities, .liquidAssets:
        //         lines.append(
        //             "\(name) | \(fmt(totals.openingCarryingAmount)) | \(fmt(totals.closingCarryingAmount))"
        //         )

        //     case .receivables:
        //         lines.append(
        //             "\(name) | \(fmt(totals.acquisitionCost)) | \(fmt(totals.openingCarryingAmount)) | \(fmt(totals.closingCarryingAmount))"
        //         )

        //     case .unclassified:
        //         lines.append(
        //             "\(name) | \(fmt(totals.acquisitionCost)) | \(fmt(totals.openingCarryingAmount)) | \(fmt(totals.closingCarryingAmount)) | \(fmt(totals.residualAmount))"
        //         )
        //     }
        // }

        // private static func renderUnderlyingRow(
        //     _ row: AssetsOverviewRow,
        //     profile: AssetsOverviewColumnProfile,
        //     into lines: inout [String]
        // ) {
        //     let marker = issueMarker(for: row)
        //     let label = "    · \(row.displayName)\(marker.isEmpty ? "" : " \(marker)")"

        //     switch profile {
        //     case .intangibleFixedAssets:
        //         lines.append(
        //             "\(label) | \(fmt(row.acquisitionCost ?? 0)) | \(fmt(row.openingCarryingAmount)) | \(fmt(row.closingCarryingAmount))"
        //         )

        //     case .tangibleFixedAssets:
        //         lines.append(
        //             "\(label) | \(fmt(row.acquisitionCost ?? 0)) | \(fmt(row.openingCarryingAmount)) | \(fmt(row.closingCarryingAmount)) | \(fmt(row.residualAmount ?? 0))"
        //         )

        //     case .financialFixedAssets, .inventory, .securities, .liquidAssets:
        //         lines.append(
        //             "\(label) | \(fmt(row.openingCarryingAmount)) | \(fmt(row.closingCarryingAmount))"
        //         )

        //     case .receivables:
        //         lines.append(
        //             "\(label) | \(fmt(row.acquisitionCost ?? 0)) | \(fmt(row.openingCarryingAmount)) | \(fmt(row.closingCarryingAmount))"
        //         )

        //     case .unclassified:
        //         lines.append(
        //             "\(label) | \(fmt(row.acquisitionCost ?? 0)) | \(fmt(row.openingCarryingAmount)) | \(fmt(row.closingCarryingAmount)) | \(fmt(row.residualAmount ?? 0))"
        //         )
        //     }
        // }

        private static func issueMarker(
            for row: AssetsOverviewRow
        ) -> String {
            switch row.highestIssueSeverity {
            case .error:
                return "[!]"
            case .warning:
                return "[~]"
            case .info:
                return "[i]"
            case nil:
                return ""
            }
        }

        private static func hasVisibleUnderlyingAmounts(
            _ row: AssetsOverviewRow
        ) -> Bool {
            (row.acquisitionCost ?? 0) != 0
                || row.openingCarryingAmount != 0
                || row.periodInvestment != 0
                || row.periodDepreciation != 0
                || row.closingCarryingAmount != 0
                || (row.residualAmount ?? 0) != 0
        }

        private static func renderVATSpecification(
            from group: AssetsOverviewGroup,
            into lines: inout [String]
        ) {
            guard let vatLine = group.lines.first(where: { $0.category == .vat_receivable }) else {
                return
            }

            lines.append("")
            lines.append("Specificatie vordering omzetbelasting")
            lines.append("Vordering omzetbelasting over dit boekjaar | \(fmt(0))")
            lines.append("Vordering omzetbelasting over het vorige boekjaar | \(fmt(vatLine.totals.openingCarryingAmount))")
            lines.append("Vordering omzetbelasting over oudere boekjaren | \(fmt(0))")
            lines.append("Totaal boekwaarde omzetbelasting | \(fmt(vatLine.totals.closingCarryingAmount))")
        }

        private static func totalOpeningAcrossVisibleSections(
            _ overview: AssetsOverview
        ) -> Decimal {
            overview.groups.reduce(0) { partial, group in
                if group.section == .unclassified {
                    return partial
                }

                return partial + group.totals.openingCarryingAmount
            }
        }

        private static func totalClosingAcrossVisibleSections(
            _ overview: AssetsOverview
        ) -> Decimal {
            overview.groups.reduce(0) { partial, group in
                if group.section == .unclassified {
                    return partial
                }

                return partial + group.totals.closingCarryingAmount
            }
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
               let residualAmount = row.residualAmount {
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

            if row.issues.isEmpty {
                lines.append("    Issues: none")
            } else {
                lines.append("    Issues:")

                for issue in row.issues.sorted(by: issueSort) {
                    lines.append("        - [\(severityLabel(issue.severity))] \(issue.message)")
                }
            }
        }

        private static func severityLabel(
            _ severity: AssetsOverviewIssueSeverity
        ) -> String {
            switch severity {
            case .error:
                return "error"
            case .warning:
                return "warning"
            case .info:
                return "info"
            }
        }

        private static func issueSort(
            lhs: AssetsOverviewIssue,
            rhs: AssetsOverviewIssue
        ) -> Bool {
            if lhs.severity != rhs.severity {
                return lhs.severity > rhs.severity
            }

            return lhs.message.localizedCaseInsensitiveCompare(rhs.message) == .orderedAscending
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

        private static func appendShareBreakdown(
            _ breakdown: [AssetsOverviewOwnerShareAmounts],
            value: KeyPath<AssetsOverviewOwnerShareAmounts, Decimal>,
            into lines: inout [String]
        ) {
            if breakdown.isEmpty {
                lines.append("    · none")
                return
            }

            for item in breakdown {
                lines.append(
                    "    · \(item.ownerLabel) | \(fmt(item[keyPath: value]))"
                )
            }
        }
    }
}
