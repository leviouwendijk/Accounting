import Foundation

public enum VATStatusBuilder {
    public static func build(
        resolvedEntries: [ResolvedEntry],
        title: String = "VAT status",
        period: PeriodWindow? = nil,
        tolerance: Decimal = 0.01,
        calendar: Calendar,
        businessEntity: BusinessEntity = .vof
    ) -> VATStatusReport {
        let allowedPeriods = period.map {
            Set(periodsOverlapping($0, calendar: calendar))
        }

        let roots = businessEntity.vatRoots

        var ordinaryByPeriod: [VATPeriod: StatusBreakdown] = [:]
        var correctionsByPeriod: [VATPeriod: Decimal] = [:]
        var taggedEntriesByPeriod: [VATPeriod: [VATAuditEntry]] = [:]

        for entry in resolvedEntries {
            guard case .absolute(let postingDate) = entry.date else {
                continue
            }

            let postingQuarter = vatPeriod(
                for: postingDate,
                calendar: calendar
            )

            let annotation = entry.vat

            if shouldIncludePosting(
                postingDate: postingDate,
                period: period
            ), shouldCountInOrdinaryLedger(annotation: annotation) {
                let breakdown = ordinaryBreakdown(
                    for: entry,
                    roots: roots
                )

                if !breakdown.isZero {
                    ordinaryByPeriod[postingQuarter, default: .zero] += breakdown
                }
            }

            guard let annotation else {
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

            switch annotation.kind {
            case .correction:
                correctionsByPeriod[annotation.period, default: 0] += event.netAmount

            case .settlement, .filing:
                break
            }
        }

        var periods = Set(ordinaryByPeriod.keys)
            .union(correctionsByPeriod.keys)
            .union(taggedEntriesByPeriod.keys)

        if let allowedPeriods {
            periods.formUnion(allowedPeriods)
        }

        var carryBag: [VATPeriod: Decimal] = [:]

        let quarters = periods
            .sorted { lhs, rhs in
                vatPeriodSort(
                    lhs: lhs,
                    rhs: rhs
                )
            }
            .map { periodKey in
                let entries = (taggedEntriesByPeriod[periodKey] ?? [])
                    .sorted { lhs, rhs in
                        auditEntrySort(
                            lhs: lhs,
                            rhs: rhs
                        )
                    }

                let ordinary = ordinaryByPeriod[periodKey] ?? .zero
                let correctionsNet = correctionsByPeriod[periodKey] ?? 0

                let carryIn = carryBag.values.reduce(0, +)

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

                let settlementNet = entries
                    .filter { $0.kind == .settlement }
                    .reduce(Decimal(0)) { $0 + $1.netAmount }

                let expectedSettlementNet =
                    carryIn
                    + ordinary.net
                    + correctionsNet

                if ordinary.net != 0 || correctionsNet != 0 {
                    carryBag[periodKey, default: 0] += ordinary.net + correctionsNet
                }

                if settlementNet != 0 {
                    carryBag[periodKey, default: 0] += settlementNet
                }

                pruneZeroes(
                    &carryBag
                )

                let residual = carryBag.values.reduce(0, +)

                let residualContributions = carryBag
                    .filter { $0.value != 0 }
                    .map { key, value in
                        VATStatusContribution(
                            sourcePeriod: key,
                            amount: value
                        )
                    }
                    .sorted { lhs, rhs in
                        vatPeriodSort(
                            lhs: lhs.sourcePeriod,
                            rhs: rhs.sourcePeriod
                        )
                    }

                return VATStatusQuarter(
                    period: periodKey,
                    carryIn: carryIn,
                    outputNet: ordinary.output,
                    deductibleNet: ordinary.deductible,
                    privateUseNet: ordinary.privateUse,
                    receivableNet: ordinary.receivable,
                    payableFallbackNet: ordinary.payableFallback,
                    ordinaryNet: ordinary.net,
                    correctionsNet: correctionsNet,
                    expectedSettlementNet: expectedSettlementNet,
                    paid: paid,
                    received: received,
                    settlementNet: settlementNet,
                    residual: residual,
                    residualContributions: residualContributions,
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

private extension VATStatusBuilder {
    struct StatusBreakdown: Sendable {
        var output: Decimal = 0
        var deductible: Decimal = 0
        var privateUse: Decimal = 0
        var receivable: Decimal = 0
        var payableFallback: Decimal = 0

        static let zero = StatusBreakdown()

        var net: Decimal {
            output
                + deductible
                + privateUse
                + receivable
                + payableFallback
        }

        var isZero: Bool {
            output == 0
                && deductible == 0
                && privateUse == 0
                && receivable == 0
                && payableFallback == 0
        }

        static func + (
            lhs: StatusBreakdown,
            rhs: StatusBreakdown
        ) -> StatusBreakdown {
            .init(
                output: lhs.output + rhs.output,
                deductible: lhs.deductible + rhs.deductible,
                privateUse: lhs.privateUse + rhs.privateUse,
                receivable: lhs.receivable + rhs.receivable,
                payableFallback: lhs.payableFallback + rhs.payableFallback
            )
        }

        static func += (
            lhs: inout StatusBreakdown,
            rhs: StatusBreakdown
        ) {
            lhs = lhs + rhs
        }
    }

    @inline(__always)
    static func shouldIncludePosting(
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
    static func shouldCountInOrdinaryLedger(
        annotation: VATAnnotation?
    ) -> Bool {
        guard let annotation else {
            return true
        }

        switch annotation.kind {
        case .settlement, .filing, .correction:
            return false
        }
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

    @inline(__always)
    static func classifyStatusFamily(
        _ code: String,
        roots: VATRoots
    ) -> VATStatusFamily? {
        if roots.excludedCodes.contains(where: { code.hasPrefix($0) }) {
            return nil
        }

        if roots.privateUseCodes.contains(where: { code.hasPrefix($0) }) {
            return .privateUse
        }

        if roots.deductibleCodes.contains(where: { code.hasPrefix($0) }) {
            return .deductible
        }

        if roots.outputCodes.contains(where: { code.hasPrefix($0) }) {
            return .output
        }

        if roots.receivableCodes.contains(where: { code.hasPrefix($0) }) {
            return .receivable
        }

        if roots.payableCodes.contains(where: { code.hasPrefix($0) }) {
            return .payableFallback
        }

        return nil
    }

    static func ordinaryBreakdown(
        for entry: ResolvedEntry,
        roots: VATRoots
    ) -> StatusBreakdown {
        var out = StatusBreakdown.zero

        for line in entry.lines {
            let code = line.account.code

            guard let family = classifyStatusFamily(
                code,
                roots: roots
            ) else {
                continue
            }

            let effect = -signedRaw(line)

            switch family {
            case .output:
                out.output += effect

            case .deductible:
                out.deductible += effect

            case .privateUse:
                out.privateUse += effect

            case .receivable:
                out.receivable += effect

            case .payableFallback:
                out.payableFallback += effect
            }
        }

        return out
    }

    static func auditMovement(
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
                owed += (-raw)
            }

            if isReceivableVATCode(
                code,
                roots: roots
            ) {
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
                classifyStatusFamily(
                    code,
                    roots: roots
                ) != nil
            }

        let movement = auditMovement(
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
            netAmount: netMovement,
            amount: DecimalFuncs.absDec(netMovement),
            vatAccountCodes: Array(Set(vatCodes)).sorted(),
            details: entry.details
        )
    }

    @inline(__always)
    static func pruneZeroes(
        _ bag: inout [VATPeriod: Decimal]
    ) {
        bag = bag.filter { _, value in
            value != 0
        }
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
