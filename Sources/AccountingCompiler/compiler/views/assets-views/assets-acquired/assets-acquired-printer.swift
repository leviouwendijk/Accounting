import Accounting
import Foundation

extension AssetViews {
    public enum AcquiredAssetsPrinter {
        public static func renderText(
            _ report: AcquiredAssetsReport,
            diagnostics: Bool = false
        ) -> String {
            var lines: [String] = []

            let title = "Assets acquired"
            lines.append(title)
            lines.append(String(repeating: "─", count: title.count))
            lines.append("Period: \(report.period.string())")
            lines.append("Anchor: \(fmtDate(report.anchor))")
            lines.append("Assets acquired: \(report.rows.count)")
            lines.append("Total acquisition cost: \(fmt(report.totalAcquisitionCost))")

            if report.skippedMissingDateCount > 0 {
                lines.append("Skipped assets missing acquisition/commission date: \(report.skippedMissingDateCount)")
            }

            if diagnostics && !report.diagnosticCounts.isEmpty {
                lines.append("")
                lines.append("Diagnostics")
                lines.append("───────────")

                for pair in report.diagnosticCounts.sorted(by: diagnosticSort) {
                    lines.append("• \(pair.key): \(pair.value)")
                }
            }

            if !report.rows.isEmpty {
                lines.append("")
                lines.append("Assets")
                lines.append("──────")

                for row in report.rows {
                    render(
                        row,
                        into: &lines
                    )
                    lines.append("")
                }

                if lines.last == "" {
                    lines.removeLast()
                }
            }

            return lines.joined(separator: "\n")
        }

        private static func render(
            _ row: AcquiredAssetRow,
            into lines: inout [String]
        ) {
            let marker = issueMarker(for: row)
            lines.append(
                "\(fmtDate(row.purchaseDate)) — \(row.displayName)\(marker.isEmpty ? "" : " \(marker)")"
            )
            lines.append("    Key: \(row.entityKey.identifier(displaying: .fullchain))")

            switch row.purchaseDateSource {
            case .acquisitionDate:
                lines.append("    Purchase date source: acquisition date")
            case .commissionDateFallback:
                lines.append("    Purchase date source: commission date fallback")
            }

            if let details = row.details {
                lines.append("    Details: \(details)")
            }

            lines.append("    Category: \(row.category.lineLabel)")

            if let type = row.type {
                lines.append("    Type: \(type)")
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

            // if let purchaseEntry = row.purchaseEntry {
            //     lines.append("    Purchase entry: \(purchaseEntry)")
            // } else {
            //     lines.append("    Purchase entry: —")
            // }
            if let acquisitionEntry = row.acquisitionEntry {
                lines.append("    Acquisition entry: \(acquisitionEntry)")
            } else {
                lines.append("    Acquisition entry: —")
            }

            if let acquisitionAccount = row.acquisitionAccount {
                lines.append("    Acquisition account: \(acquisitionAccount.debugString)")
            } else {
                lines.append("    Acquisition account: —")
            }

            if !row.ownerShares.isEmpty {
                lines.append("    Shares:")

                for share in row.ownerShares {
                    lines.append(
                        "        - \(share.ownerLabel): \(fmtPct(share.percentage)) → \(fmt(share.amount))"
                    )
                }
            }

            if !row.issues.isEmpty {
                lines.append("    Issues:")

                for issue in row.issues.sorted(by: issueSort) {
                    lines.append("        - [\(severityLabel(issue.severity))] \(issue.message)")
                }
            }
        }

        private static func issueMarker(
            for row: AcquiredAssetRow
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
    }
}
