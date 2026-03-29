import Foundation

public extension AssetViews {
    enum AssetSharesHistoryPrinter {
        public static func renderText(
            _ report: AssetSharesHistoryReport
        ) -> String {
            var lines: [String] = []

            lines.append(report.title)
            lines.append(String(repeating: "─", count: report.title.count))

            if report.periods.isEmpty {
                lines.append("(no periods)")
                return lines.joined(separator: "\n")
            }

            for (index, period) in report.periods.enumerated() {
                if index > 0 {
                    lines.append("")
                }

                let heading = period.period.string()
                lines.append("")
                lines.append(heading)
                lines.append(String(repeating: "—", count: heading.count))

                lines.append("Som activa-aandelen begin boekjaar | \(fmt(period.openingCarryingAmount))")
                appendShareBreakdown(
                    period.breakdown,
                    value: \.openingCarryingAmount,
                    into: &lines
                )

                lines.append("Som activa-aandelen investeringen in periode | \(fmt(period.periodInvestment))")
                appendShareBreakdown(
                    period.breakdown,
                    value: \.periodInvestment,
                    into: &lines
                )

                lines.append("Som activa-aandelen einde boekjaar | \(fmt(period.closingCarryingAmount))")
                appendShareBreakdown(
                    period.breakdown,
                    value: \.closingCarryingAmount,
                    into: &lines
                )
            }

            while lines.last == "" {
                lines.removeLast()
            }

            return lines.joined(separator: "\n")
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
