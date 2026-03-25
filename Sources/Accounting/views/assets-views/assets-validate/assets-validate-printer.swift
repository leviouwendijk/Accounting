import Foundation

extension AssetViews {
    public enum AssetValidationPrinter {
        public static func renderText(
            _ report: AssetValidationReport,
            diagnostics: Bool = false,
            onlyFlagged: Bool = false
        ) -> String {
            var lines: [String] = []

            let title = "Assets validate"
            lines.append(title)
            lines.append(String(repeating: "─", count: title.count))
            lines.append("Assets inspected: \(report.rows.count)")
            lines.append("Flagged assets: \(report.flaggedRows.count)")

            if diagnostics && !report.diagnosticsCounts.isEmpty {
                lines.append("")
                lines.append("Diagnostics")
                lines.append("───────────")

                for pair in report.diagnosticsCounts.sorted(by: diagnosticSort) {
                    lines.append("• \(pair.key): \(pair.value)")
                }
            }

            let rows = onlyFlagged ? report.flaggedRows : report.rows

            if !rows.isEmpty {
                lines.append("")
                lines.append("Assets")
                lines.append("──────")

                for row in rows {
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
            _ row: AssetValidationRow,
            into lines: inout [String]
        ) {
            let marker = issueMarker(for: row)
            lines.append(
                "\(row.displayName)\(marker.isEmpty ? "" : " \(marker)")"
            )
            lines.append("    Key: \(row.entityKey.identifier(displaying: .fullchain))")

            if let details = row.details {
                lines.append("    Details: \(details)")
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

            if let acquisitionCost = row.acquisitionCost {
                lines.append("    Profile acquisition valuation: \(fmt(acquisitionCost))")
            } else {
                lines.append("    Profile acquisition valuation: —")
            }

            lines.append("    Matched ledger amount: \(fmt(row.matchedLedgerAmount))")

            if let delta = row.delta {
                lines.append("    Delta: \(fmt(delta))")
            } else {
                lines.append("    Delta: —")
            }

            if !row.ledgerMatches.isEmpty {
                lines.append("    Ledger matches:")

                for match in row.ledgerMatches {
                    let direction: String = {
                        switch match.direction {
                        case .debit:
                            return "debit"
                        case .credit:
                            return "credit"
                        }
                    }()

                    let entryID = match.entryId.map(String.init) ?? "—"

                    lines.append(
                        "        - entry \(entryID) | \(fmtDate(match.date)) | \(direction) | \(fmt(match.amount))"
                    )
                }
            }

            if !row.issues.isEmpty {
                lines.append("    Issues:")

                for issue in row.issues.sorted(by: issueSort) {
                    lines.append(
                        "        - [\(severityLabel(issue.severity))] \(issue.message)"
                    )
                }
            }
        }

        private static func issueMarker(
            for row: AssetValidationRow
        ) -> String {
            switch row.highestSeverity {
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
            _ severity: AssetAcquisitionValidationSeverity
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
            lhs: AssetAcquisitionValidationIssue,
            rhs: AssetAcquisitionValidationIssue
        ) -> Bool {
            let lhsRank = severityRank(lhs.severity)
            let rhsRank = severityRank(rhs.severity)

            if lhsRank != rhsRank {
                return lhsRank > rhsRank
            }

            return lhs.message.localizedCaseInsensitiveCompare(
                rhs.message
            ) == .orderedAscending
        }

        private static func diagnosticSort(
            lhs: (key: String, value: Int),
            rhs: (key: String, value: Int)
        ) -> Bool {
            if lhs.value != rhs.value {
                return lhs.value > rhs.value
            }

            return lhs.key.localizedCaseInsensitiveCompare(
                rhs.key
            ) == .orderedAscending
        }

        private static func severityRank(
            _ severity: AssetAcquisitionValidationSeverity
        ) -> Int {
            switch severity {
            case .error:
                return 2
            case .warning:
                return 1
            case .info:
                return 0
            }
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
