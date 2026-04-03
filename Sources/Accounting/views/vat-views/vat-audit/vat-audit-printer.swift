import Foundation

public struct VATAuditTextOptions: Sendable {
    public var title: String
    public var showHeader: Bool
    public var showEntries: Bool
    public var onlyFlagged: Bool
    public var fractionDigits: Int?

    public init(
        title: String = "VAT audit trail",
        showHeader: Bool = true,
        showEntries: Bool = true,
        onlyFlagged: Bool = false,
        fractionDigits: Int? = 2
    ) {
        self.title = title
        self.showHeader = showHeader
        self.showEntries = showEntries
        self.onlyFlagged = onlyFlagged
        self.fractionDigits = fractionDigits
    }

    public var underline: String {
        String(repeating: "─", count: title.count)
    }
}

public extension VATAuditReport {
    func renderText(
        _ opts: VATAuditTextOptions = .init()
    ) -> String {
        func fmt(
            _ x: Decimal
        ) -> String {
            guard let digits = opts.fractionDigits else {
                return x.description
            }

            var value = x
            var rounded = Decimal()
            NSDecimalRound(&rounded, &value, digits, .plain)

            let formatter = NumberFormatter()
            formatter.locale = Locale(identifier: "nl_NL")
            formatter.numberStyle = .decimal
            formatter.minimumFractionDigits = digits
            formatter.maximumFractionDigits = digits

            return formatter.string(
                from: rounded as NSDecimalNumber
            ) ?? rounded.description
        }

        func quarterLabel(
            _ period: VATPeriod
        ) -> String {
            "\(period.year)Q\(period.quarter.rawValue)"
        }

        func dateLabel(
            _ date: Date
        ) -> String {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            formatter.dateFormat = "yyyy-MM-dd"
            return formatter.string(from: date)
        }

        let rows = opts.onlyFlagged
            ? flaggedQuarters
            : quarters

        var out: [String] = []

        if opts.showHeader {
            out.append(opts.title)
            out.append(opts.underline)
        }

        out.append("Quarters: \(rows.count)")
        out.append("Flagged: \(rows.filter { absDec($0.ledgerVsDeclaredDelta) > tolerance }.count)")
        out.append("Tolerance: \(fmt(tolerance))")
        out.append("")
        out.append("Totals")
        out.append("──────")
        out.append("Ledger owed:       \(fmt(totalLedgerOwed))")
        out.append("Ledger receivable: \(fmt(totalLedgerReceivable))")
        out.append("Ledger net:        \(fmt(totalLedgerNet))")
        out.append("Filed:             \(fmt(totalFiled))")
        out.append("Paid:              \(fmt(totalPaid))")
        out.append("Refunded:          \(fmt(totalRefunded))")
        out.append("Corrected:         \(fmt(totalCorrected))")
        out.append("Ledger vs declared Δ: \(fmt(totalLedgerVsDeclaredDelta))")

        if rows.isEmpty {
            out.append("")
            out.append("(no quarters)")
            return out.joined(separator: "\n")
        }

        for quarter in rows {
            out.append("")
            out.append(quarterLabel(quarter.period))
            out.append(String(repeating: "─", count: quarterLabel(quarter.period).count))

            out.append("ledger owed:       \(fmt(quarter.ledgerOwed))")
            out.append("ledger receivable: \(fmt(quarter.ledgerReceivable))")
            out.append("ledger net:        \(fmt(quarter.ledgerNet))")
            out.append("filed:             \(fmt(quarter.filed))")
            out.append("paid:              \(fmt(quarter.paid))")
            out.append("refunded:          \(fmt(quarter.refunded))")
            out.append("corrected:         \(fmt(quarter.corrected))")
            out.append("ledger vs declared Δ: \(fmt(quarter.ledgerVsDeclaredDelta))")

            if !opts.showEntries {
                continue
            }

            if quarter.entries.isEmpty {
                out.append("entries: none")
                continue
            }

            out.append("entries:")

            for entry in quarter.entries {
                let codes = entry.vatAccountCodes.isEmpty
                    ? "—"
                    : entry.vatAccountCodes.joined(separator: ", ")

                out.append(
                    "  • \(entry.kind.rawValue)  \(fmt(entry.amount))  "
                        + "\(dateLabel(entry.postingDate))"
                        + (entry.entryId.map { "  [entry \($0)]" } ?? "")
                )
                out.append("    codes: \(codes)")

                if let details = entry.details,
                   !details.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    out.append("    details: \(details)")
                }
            }
        }

        return out.joined(separator: "\n")
    }
}

@inline(__always)
private func absDec(
    _ value: Decimal
) -> Decimal {
    value < 0 ? -value : value
}
