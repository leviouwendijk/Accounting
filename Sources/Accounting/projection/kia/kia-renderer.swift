import Foundation

public enum KIARenderer {
    public static func renderText(
        _ result: KIAProjectionResult,
        verbose: Bool = false
    ) -> String {
        var lines: [String] = []

        lines.append("KIA \(result.taxYear)")
        lines.append("────────")
        lines.append("Qualifying investment total: \(fmt(result.qualifyingInvestmentTotal))")
        lines.append("Deduction: \(fmt(result.deduction))")
        lines.append("Qualified assets: \(result.qualifiedAssets.count)")
        lines.append("Excluded assets: \(result.excludedAssets.count)")

        guard verbose else {
            return lines.joined(separator: "\n")
        }

        if !result.qualifiedAssets.isEmpty {
            lines.append("")
            lines.append("Qualified assets")
            lines.append("────────────────")

            for asset in result.qualifiedAssets {
                lines.append("\(asset.displayName)")
                lines.append("    Date: \(dateString(asset.acquisitionDate))")
                lines.append("    Total amount: \(fmt(asset.totalAmount))")
                lines.append("    Qualifying amount: \(fmt(asset.qualifyingAmount))")

                if asset.shares.isEmpty {
                    lines.append("    Shares: none")
                } else {
                    lines.append("    Shares:")
                    for share in asset.shares {
                        lines.append(
                            "        - \(share.ownerLabel): \(fmt(share.percentage))% → \(fmt(share.amount))"
                        )
                    }
                }
            }
        }

        if !result.excludedAssets.isEmpty {
            lines.append("")
            lines.append("Excluded assets")
            lines.append("───────────────")

            for excluded in result.excludedAssets {
                lines.append(
                    "\(excluded.entityKey.identifier(displaying: .fullchain))"
                )
                lines.append("    Reason: \(reasonString(excluded.reason))")
            }
        }

        return lines.joined(separator: "\n")
    }

    private static func fmt(_ value: Decimal) -> String {
        let nf = NumberFormatter()
        nf.locale = Locale(identifier: "nl_NL")
        nf.numberStyle = .decimal
        nf.minimumFractionDigits = 2
        nf.maximumFractionDigits = 2
        return nf.string(from: value as NSDecimalNumber) ?? value.description
    }

    private static func dateString(_ date: Date) -> String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.dateFormat = "yyyy-MM-dd"
        return df.string(from: date)
    }

    private static func reasonString(_ reason: KIAQualificationReason) -> String {
        switch reason {
        case .missingDepreciation:
            return "Missing depreciation config"
        case .missingEffectiveDate:
            return "Missing effective/acquisition date"
        case .missingAcquisitionCost:
            return "Missing acquisition cost"
        case .belowMinimumAssetAmount(let amount):
            return "Below minimum qualifying asset amount (€450): \(fmt(amount))"
        case .outsideTaxYear:
            return "Outside requested tax year"
        case .invalidShareConfiguration(let message):
            return "Invalid share configuration: \(message)"
        }
    }
}
