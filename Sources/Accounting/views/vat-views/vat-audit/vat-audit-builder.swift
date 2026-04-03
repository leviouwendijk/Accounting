import Foundation

public enum VATAuditBuilder {
    public static func build(
        resolvedEntries: [ResolvedEntry],
        title: String = "VAT audit trail",
        period: PeriodWindow? = nil,
        tolerance: Decimal = 0.01,
        calendar: Calendar
    ) -> VATAuditReport {
        let allowedPeriods = period.map {
            Set(periodsOverlapping($0, calendar: calendar))
        }

        var ledgerOwedByPeriod: [VATPeriod: Decimal] = [:]
        var ledgerReceivableByPeriod: [VATPeriod: Decimal] = [:]
        var taggedEntriesByPeriod: [VATPeriod: [VATAuditEntry]] = [:]

        for entry in resolvedEntries {
            guard case .absolute(let postingDate) = entry.date else {
                continue
            }

            let postingQuarter = vatPeriod(
                for: postingDate,
                calendar: calendar
            )

            if shouldIncludeLedgerPosting(
                postingDate: postingDate,
                period: period
            ) {
                let movement = vatLedgerMovement(
                    for: entry
                )

                if movement.owed != 0 {
                    ledgerOwedByPeriod[postingQuarter, default: 0] += movement.owed
                }

                if movement.receivable != 0 {
                    ledgerReceivableByPeriod[postingQuarter, default: 0] += movement.receivable
                }
            }

            guard let annotation = entry.vat else {
                continue
            }

            if let allowedPeriods,
               !allowedPeriods.contains(annotation.period) {
                continue
            }

            let event = makeAuditEntry(
                entry: entry,
                postingDate: postingDate,
                annotation: annotation
            )

            taggedEntriesByPeriod[annotation.period, default: []].append(
                event
            )
        }

        var periods = Set(ledgerOwedByPeriod.keys)
            .union(ledgerReceivableByPeriod.keys)
            .union(taggedEntriesByPeriod.keys)

        if let allowedPeriods {
            periods.formUnion(allowedPeriods)
        }

        let quarters = periods
            .sorted(by: vatPeriodSort)
            .map { periodKey in
                let entries = (taggedEntriesByPeriod[periodKey] ?? [])
                    .sorted(by: auditEntrySort)

                let filed = entries
                    .filter { $0.kind == .filing }
                    .reduce(Decimal(0)) { $0 + $1.amount }

                let paid = entries
                    .filter { $0.kind == .payment }
                    .reduce(Decimal(0)) { $0 + $1.amount }

                let refunded = entries
                    .filter { $0.kind == .refund }
                    .reduce(Decimal(0)) { $0 + $1.amount }

                let corrected = entries
                    .filter { $0.kind == .correction }
                    .reduce(Decimal(0)) { $0 + $1.amount }

                let ledgerOwed = ledgerOwedByPeriod[periodKey] ?? 0
                let ledgerReceivable = ledgerReceivableByPeriod[periodKey] ?? 0
                let ledgerNet = ledgerOwed - ledgerReceivable
                let ledgerVsDeclaredDelta = ledgerNet - (filed + corrected)

                return VATAuditQuarter(
                    period: periodKey,
                    ledgerOwed: ledgerOwed,
                    ledgerReceivable: ledgerReceivable,
                    ledgerNet: ledgerNet,
                    filed: filed,
                    paid: paid,
                    refunded: refunded,
                    corrected: corrected,
                    ledgerVsDeclaredDelta: ledgerVsDeclaredDelta,
                    entries: entries
                )
            }

        return .init(
            title: title,
            quarters: quarters,
            tolerance: tolerance
        )
    }
}

private extension VATAuditBuilder {
    static let payablePrefixes: [String] = [
        "BSchBepBtw",
        "BSchBepEob",
        "BSchBepBaf",
    ]

    static let receivablePrefixes: [String] = [
        "BVorVbkTvo",
        "BVorVbkEob",
    ]

    static func shouldIncludeLedgerPosting(
        postingDate: Date,
        period: PeriodWindow?
    ) -> Bool {
        guard let period else {
            return true
        }

        return contains(
            postingDate,
            in: period
        )
    }

    static func contains(
        _ date: Date,
        in window: PeriodWindow
    ) -> Bool {
        if let from = window.from, date < from {
            return false
        }

        if let to = window.to, date > to {
            return false
        }

        return true
    }

    static func vatLedgerMovement(
        for entry: ResolvedEntry
    ) -> (owed: Decimal, receivable: Decimal) {
        var owed: Decimal = 0
        var receivable: Decimal = 0

        for line in entry.lines {
            let code = line.account.code
            let raw = signedRaw(line)

            if payablePrefixes.contains(where: { code.hasPrefix($0) }) {
                // liability normal balance = credit
                owed += (-raw)
            }

            if receivablePrefixes.contains(where: { code.hasPrefix($0) }) {
                // asset normal balance = debit
                receivable += raw
            }
        }

        return (owed, receivable)
    }

    static func makeAuditEntry(
        entry: ResolvedEntry,
        postingDate: Date,
        annotation: VATAnnotation
    ) -> VATAuditEntry {
        let vatCodes = entry.lines
            .map(\.account.code)
            .filter { code in
                payablePrefixes.contains(where: { code.hasPrefix($0) })
                    || receivablePrefixes.contains(where: { code.hasPrefix($0) })
            }

        let movement = vatLedgerMovement(
            for: entry
        )

        let netMovement = movement.owed - movement.receivable

        return .init(
            entryId: entry.id,
            postingDate: postingDate,
            kind: annotation.kind,
            period: annotation.period,
            amount: DecimalFuncs.absDec(netMovement),
            vatAccountCodes: Array(Set(vatCodes)).sorted(),
            details: entry.details
        )
    }

    static func signedRaw(
        _ line: ResolvedLine
    ) -> Decimal {
        line.direction == .debit
            ? line.amount
            : -line.amount
    }

    static func vatPeriod(
        for date: Date,
        calendar: Calendar
    ) -> VATPeriod {
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)

        let quarter: VATQuarter = switch month {
        case 1...3:
            .q1
        case 4...6:
            .q2
        case 7...9:
            .q3
        default:
            .q4
        }

        return .init(
            year: year,
            quarter: quarter
        )
    }

    static func periodsOverlapping(
        _ window: PeriodWindow,
        calendar: Calendar
    ) -> [VATPeriod] {
        guard let from = window.from else {
            return []
        }

        let to = window.to ?? from

        var cursor = startOfQuarter(
            containing: from,
            calendar: calendar
        )

        var result: [VATPeriod] = []

        while cursor <= to {
            result.append(
                vatPeriod(for: cursor, calendar: calendar)
            )

            guard let next = calendar.date(
                byAdding: .month,
                value: 3,
                to: cursor
            ) else {
                break
            }

            cursor = next
        }

        return result
    }

    static func startOfQuarter(
        containing date: Date,
        calendar: Calendar
    ) -> Date {
        let comps = calendar.dateComponents(
            [.year, .month],
            from: date
        )

        let month = comps.month ?? 1
        let startMonth = (((month - 1) / 3) * 3) + 1

        return calendar.date(
            from: DateComponents(
                timeZone: calendar.timeZone,
                year: comps.year,
                month: startMonth,
                day: 1
            )
        ) ?? date
    }

    static func vatPeriodSort(
        lhs: VATPeriod,
        rhs: VATPeriod
    ) -> Bool {
        if lhs.year != rhs.year {
            return lhs.year < rhs.year
        }

        return lhs.quarter.rawValue < rhs.quarter.rawValue
    }

    static func auditEntrySort(
        lhs: VATAuditEntry,
        rhs: VATAuditEntry
    ) -> Bool {
        if lhs.postingDate != rhs.postingDate {
            return lhs.postingDate < rhs.postingDate
        }

        switch (lhs.entryId, rhs.entryId) {
        case let (.some(a), .some(b)):
            return a < b
        case (.some, .none):
            return true
        case (.none, .some):
            return false
        case (.none, .none):
            return lhs.kind.rawValue < rhs.kind.rawValue
        }
    }
}
