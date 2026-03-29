import Foundation

extension CostViews {
    public enum CostBreakdownPrinter {
        public static func renderText(
            _ report: CostBreakdownReport,
            showMembers: Bool = true,
            omitZeroMembers: Bool = true,
            showReconciliation: Bool = true
        ) -> String {
            var lines: [String] = []

            lines.append(report.title)
            lines.append(String(repeating: "─", count: report.title.count))
            lines.append("Period: \(report.period.string())")

            for bucket in report.buckets {
                lines.append("\(bucket.label) | \(fmt(bucket.amount))")

                guard showMembers else {
                    continue
                }

                let visibleMembers = bucket.members.filter { member in
                    !omitZeroMembers || member.amount != 0
                }

                for member in visibleMembers {
                    lines.append(
                        "    · \(member.label) [\(member.code)] | \(fmt(member.amount))"
                    )
                }
            }

            lines.append("Totaal overige bedrijfskosten | \(fmt(report.total))")

            if showReconciliation {
                let reconciliation = report.reconciliation

                lines.append("")
                lines.append("Reconciliation")
                lines.append("──────────────")
                lines.append(
                    "Bronpost \(reconciliation.sourceCode) (\(reconciliation.sourceLabel)) | \(fmt(reconciliation.sourceTotal))"
                )
                lines.append(
                    "Som directe WBed-subgroepen | \(fmt(reconciliation.childRootTotal))"
                )
                lines.append(
                    "Verschil root vs directe subgroepen | \(fmt(reconciliation.childRootDifference))"
                )
                lines.append(
                    "Som filing buckets | \(fmt(reconciliation.bucketTotal))"
                )
                lines.append(
                    "Verschil root vs filing buckets | \(fmt(reconciliation.difference))"
                )
                lines.append(
                    "Andere kosten residual | \(fmt(reconciliation.otherResidual))"
                )
                lines.append(
                    "Som overige directe subgroepen | \(fmt(reconciliation.otherChildrenTotal))"
                )
                lines.append(
                    "Verschil residual vs overige subgroepen | \(fmt(reconciliation.otherDifference))"
                )
                lines.append(
                    "Tolerance | \(fmt(reconciliation.tolerance))"
                )
                lines.append(
                    "Status | \(reconciliation.passed ? "ok" : "FAIL")"
                )
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
