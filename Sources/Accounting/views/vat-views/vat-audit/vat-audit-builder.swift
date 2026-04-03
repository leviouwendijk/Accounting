import Foundation

public enum VATAuditBuilder {
    public static func build(
        resolvedEntries: [ResolvedEntry],
        title: String = "VAT audit trail",
        period: PeriodWindow? = nil,
        tolerance: Decimal = 0.01,
        calendar: Calendar,
        businessEntity: BusinessEntity = .vof
    ) -> VATAuditReport {
        let allowedPeriods = period.map {
            Set(periodsOverlapping($0, calendar: calendar))
        }

        let roots = businessEntity.vatRoots

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
                    for: entry,
                    roots: roots
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
                annotation: annotation,
                roots: roots
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
            .sorted { lhs, rhs in
                Self.vatPeriodSort(
                    lhs: lhs,
                    rhs: rhs
                )
            }
            .map { periodKey in
                let entries = (taggedEntriesByPeriod[periodKey] ?? [])
                    .sorted { lhs, rhs in
                        Self.auditEntrySort(
                            lhs: lhs,
                            rhs: rhs
                        )
                    }

                let filed = entries
                    .filter { $0.kind == .filing }
                    .reduce(Decimal(0)) { $0 + $1.amount }

                let paid = entries
                    .filter {
                        $0.kind == .settlement
                            && $0.settlementFlow == .paid
                    }
                    .reduce(Decimal(0)) { $0 + $1.amount }

                let received = entries
                    .filter {
                        $0.kind == .settlement
                            && $0.settlementFlow == .received
                    }
                    .reduce(Decimal(0)) { $0 + $1.amount }

                let corrected = entries
                    .filter { $0.kind == .correction }
                    .reduce(Decimal(0)) { $0 + $1.amount }

                let ledgerOwed = ledgerOwedByPeriod[periodKey] ?? 0
                let ledgerReceivable = ledgerReceivableByPeriod[periodKey] ?? 0
                let ledgerNet = ledgerOwed - ledgerReceivable

                // Keep this semantic as-is:
                // compare ledger VAT position vs declared obligation/corrections.
                let ledgerVsDeclaredDelta = ledgerNet - (filed + corrected)

                return VATAuditQuarter(
                    period: periodKey,
                    ledgerOwed: ledgerOwed,
                    ledgerReceivable: ledgerReceivable,
                    ledgerNet: ledgerNet,
                    filed: filed,
                    paid: paid,
                    received: received,
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
    @inline(__always)
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

    @inline(__always)
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

    @inline(__always)
    static func matchesAnyPrefix(
        _ code: String,
        prefixes: [String],
        excluded: [String]
    ) -> Bool {
        guard !excluded.contains(where: { code.hasPrefix($0) }) else {
            return false
        }

        return prefixes.contains(where: { code.hasPrefix($0) })
    }

    @inline(__always)
    static func isPayableVATCode(
        _ code: String,
        roots: VATRoots
    ) -> Bool {
        matchesAnyPrefix(
            code,
            prefixes: roots.payableCodes,
            excluded: roots.excludedCodes
        )
    }

    @inline(__always)
    static func isReceivableVATCode(
        _ code: String,
        roots: VATRoots
    ) -> Bool {
        matchesAnyPrefix(
            code,
            prefixes: roots.receivableCodes,
            excluded: roots.excludedCodes
        )
    }

    static func vatLedgerMovement(
        for entry: ResolvedEntry,
        roots: VATRoots
    ) -> (owed: Decimal, receivable: Decimal) {
        var owed: Decimal = 0
        var receivable: Decimal = 0

        for line in entry.lines {
            let code = line.account.code
            let raw = signedRaw(line)

            if isPayableVATCode(
                code,
                roots: roots
            ) {
                // liability normal balance = credit
                owed += (-raw)
            }

            if isReceivableVATCode(
                code,
                roots: roots
            ) {
                // asset normal balance = debit
                receivable += raw
            }
        }

        return (
            owed,
            receivable
        )
    }

    static func inferredSettlementFlow(
        kind: VATKind,
        netMovement: Decimal
    ) -> VATSettlementFlow? {
        guard kind == .settlement else {
            return nil
        }

        if netMovement > 0 {
            return .received
        }

        if netMovement < 0 {
            return .paid
        }

        return nil
    }

    static func makeAuditEntry(
        entry: ResolvedEntry,
        postingDate: Date,
        annotation: VATAnnotation,
        roots: VATRoots
    ) -> VATAuditEntry {
        let vatCodes = entry.lines
            .map(\.account.code)
            .filter { code in
                isPayableVATCode(
                    code,
                    roots: roots
                ) || isReceivableVATCode(
                    code,
                    roots: roots
                )
            }

        let movement = vatLedgerMovement(
            for: entry,
            roots: roots
        )

        let netMovement = movement.owed - movement.receivable
        let settlementFlow = inferredSettlementFlow(
            kind: annotation.kind,
            netMovement: netMovement
        )

        return .init(
            entryId: entry.id,
            postingDate: postingDate,
            kind: annotation.kind,
            settlementFlow: settlementFlow,
            period: annotation.period,
            amount: DecimalFuncs.absDec(netMovement),
            vatAccountCodes: Array(Set(vatCodes)).sorted(),
            details: entry.details
        )
    }

    @inline(__always)
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
        guard let start = window.from, let end = window.to else {
            return []
        }

        var periods: [VATPeriod] = []
        var seen = Set<VATPeriod>()
        var current = start

        while current <= end {
            let period = vatPeriod(
                for: current,
                calendar: calendar
            )

            if seen.insert(period).inserted {
                periods.append(period)
            }

            guard let next = calendar.date(
                byAdding: .month,
                value: 1,
                to: current
            ) else {
                break
            }

            current = next
        }

        return periods
    }

    @inline(__always)
    static func vatPeriodSort(
        lhs: VATPeriod,
        rhs: VATPeriod
    ) -> Bool {
        if lhs.year != rhs.year {
            return lhs.year < rhs.year
        }

        return lhs.quarter.rawValue < rhs.quarter.rawValue
    }

    @inline(__always)
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
