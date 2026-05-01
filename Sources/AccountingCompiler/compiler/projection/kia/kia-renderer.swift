import Accounting
import Foundation

public enum KIARenderer {
    public static func renderText(
        _ result: KIAProjectionResult,
        verbose: Bool = false,
        diagnostics: Bool = false
    ) -> String {
        var lines: [String] = []

        lines.append("KIA \(result.taxYear)")
        lines.append("────────")
        lines.append("Qualifying investment total: \(fmt(result.qualifyingInvestmentTotal))")
        lines.append("Deduction: \(fmt(result.deduction))")
        lines.append("Qualified assets: \(result.qualifiedAssets.count)")
        lines.append("Excluded assets: \(result.excludedAssets.count)")

        let deductionByOwner = aggregateDeductionByOwner(result)

        if !deductionByOwner.isEmpty {
            lines.append("")
            lines.append("Deduction by owner")
            lines.append("──────────────────")

            for owner in deductionByOwner {
                lines.append(
                    "\(owner.ownerLabel): \(fmt(owner.qualifyingAmount)) → \(fmt(owner.deductionAmount))"
                )
            }
        }

        if diagnostics {
            let inspectedCount = result.diagnostics.count
            let candidateCount = result.diagnostics.filter { $0.wasCandidate }.count
            let summary = summarizeDiagnostics(result.diagnostics)

            lines.append("")
            lines.append("Diagnostics summary")
            lines.append("──────────────────")
            lines.append("Inspected entities: \(inspectedCount)")
            lines.append("Candidate entities: \(candidateCount)")
            lines.append("Qualified outcomes: \(summary.qualifiedCount)")
            lines.append("Excluded outcomes: \(summary.excludedCount)")

            if !summary.reasonCounts.isEmpty {
                lines.append("")
                lines.append("Exclusion reasons")
                lines.append("────────────────")
                for item in summary.reasonCounts.sorted(by: { lhs, rhs in
                    if lhs.value == rhs.value {
                        return lhs.key < rhs.key
                    }
                    return lhs.value > rhs.value
                }) {
                    lines.append("\(item.key): \(item.value)")
                }
            }
        }

        if !result.qualifiedAssets.isEmpty {
            lines.append("")
            lines.append("Qualified assets")
            lines.append("────────────────")

            for asset in result.qualifiedAssets {
                lines.append("\(asset.displayName)")
                lines.append("    Key: \(asset.entityKey.identifier(displaying: .fullchain))")
                if let details = asset.details, !details.isEmpty {
                    lines.append("    Details: \(details)")
                }
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

        if 
            verbose,
            !result.excludedAssets.isEmpty 
        {
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

        if diagnostics {
            lines.append("")
            lines.append("Per-entity diagnostics")
            lines.append("──────────────────────")

            for record in result.diagnostics {
                lines.append(record.entityKey.identifier(displaying: .fullchain))
                lines.append("    Display name: \(record.displayName)")
                lines.append("    Candidate: \(record.wasCandidate ? "yes" : "no")")
                lines.append("    Commission date: \(record.commissionDate.map(dateString) ?? "—")")
                lines.append("    Acquisition cost: \(record.acquisitionCost.map(fmt) ?? "—")")
                lines.append("    Share summary: \(record.shareSummary ?? "—")")
                lines.append("    Outcome: \(outcomeString(record.outcome))")
            }
        }

        return lines.joined(separator: "\n")
    }

    private struct OwnerDeductionSummary: Sendable, Hashable {
        let ownerLabel: String
        let qualifyingAmount: Decimal
        let deductionAmount: Decimal
    }

    private static func aggregateDeductionByOwner(
        _ result: KIAProjectionResult
    ) -> [OwnerDeductionSummary] {
        guard result.qualifyingInvestmentTotal > 0 else {
            return []
        }

        let ratio = result.deduction / result.qualifyingInvestmentTotal
        var totalsByOwner: [String: Decimal] = [:]

        for asset in result.qualifiedAssets {
            for share in asset.shares {
                totalsByOwner[share.ownerLabel, default: 0] += share.amount
            }
        }

        return totalsByOwner
            .map { ownerLabel, qualifyingAmount in
                OwnerDeductionSummary(
                    ownerLabel: ownerLabel,
                    qualifyingAmount: qualifyingAmount,
                    deductionAmount: qualifyingAmount * ratio
                )
            }
            .sorted { lhs, rhs in
                lhs.ownerLabel < rhs.ownerLabel
            }
    }

    private static func summarizeDiagnostics(
        _ diagnostics: [KIADiagnosticRecord]
    ) -> (
        qualifiedCount: Int,
        excludedCount: Int,
        reasonCounts: [String: Int]
    ) {
        var qualifiedCount = 0
        var excludedCount = 0
        var reasonCounts: [String: Int] = [:]

        for record in diagnostics {
            switch record.outcome {
            case .qualified:
                qualifiedCount += 1

            case .excluded(let reason):
                excludedCount += 1
                let key = reasonString(reason)
                reasonCounts[key, default: 0] += 1
            }
        }

        return (qualifiedCount, excludedCount, reasonCounts)
    }

    private static func outcomeString(
        _ outcome: KIADiagnosticOutcome
    ) -> String {
        switch outcome {
        case .qualified:
            return "qualified"
        case .excluded(let reason):
            return "excluded — \(reasonString(reason))"
        }
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

        case .missingProfile:
            return "Missing profile"

        case .missingCommissionDate:
            return "Missing commission date"

        case .missingAcquisitionCost:
            return "Missing acquisition cost"

        case .belowMinimumAssetAmount(let amount):
            return "Below minimum qualifying asset amount (€450): \(fmt(amount))"

        case .outsideTaxYear(let actualYear):
            if let actualYear {
                return "Outside requested tax year (actual year: \(actualYear))"
            }
            return "Outside requested tax year"

        case .invalidShareConfiguration(let message):
            return "Invalid share configuration: \(message)"

        case .notAssetCandidate:
            return "Not an asset candidate"
        }
    }
}
