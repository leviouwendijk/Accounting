import Accounting
import Foundation

extension AssetViews {
    public enum AssetFilingReconciliationPrinter {
        public static func renderText(
            _ report: AssetFilingReconciliationReport,
            showMatchedCodes: Bool = true
        ) -> String {
            var lines: [String] = []

            let title = "Asset filing reconciliation"
            lines.append(title)
            lines.append(String(repeating: "─", count: title.count))
            lines.append("Period: \(report.period.string())")
            lines.append("Checks: \(report.checkCount)")
            lines.append("Failures: \(report.failureCount)")
            lines.append("Tolerance: \(fmt(report.tolerance))")

            if !report.uncheckedSections.isEmpty {
                lines.append("Unchecked sections: \(report.uncheckedSections.map(\.label).joined(separator: ", "))")
            }

            let sections = Array(
                Set(report.rows.map(\.section))
            ).sorted { lhs, rhs in
                lhs.sortOrder < rhs.sortOrder
            }

            for section in sections {
                let rows = report.rows.filter { $0.section == section }

                lines.append("")
                lines.append(section.label)
                lines.append(String(repeating: "─", count: max(section.label.count, 8)))

                for row in rows {
                    let status = row.passed ? "ok" : "FAIL"
                    lines.append(
                        "• \(row.metric.label): projected \(fmt(row.projected)) | ledger \(fmt(row.ledger)) | diff \(fmt(row.difference)) | \(status)"
                    )
                    lines.append("  Selector: \(row.ledgerSelector)")

                    if showMatchedCodes {
                        if row.matchedCodes.isEmpty {
                            lines.append("  Matched codes: —")
                        } else {
                            lines.append("  Matched codes: \(row.matchedCodes.joined(separator: ", "))")
                        }
                    }

                    if !row.notes.isEmpty {
                        for note in row.notes {
                            lines.append("  Note: \(note)")
                        }
                    }
                }
            }

            return lines.joined(separator: "\n")
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
    }
}
