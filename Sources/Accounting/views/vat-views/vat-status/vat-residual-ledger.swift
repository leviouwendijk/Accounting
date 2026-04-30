import Foundation

public struct VATResidualLot: Sendable, Codable, Hashable {
    public let sourcePeriod: VATPeriod
    public let postingDate: Date
    public let entryId: Int?
    public let family: VATStatusFamily
    public let code: String
    public let label: String
    public let kind: VATKind
    public let isSettlementRemainder: Bool
    public let originalAmount: Decimal
    public let remainingAmount: Decimal

    public init(
        sourcePeriod: VATPeriod,
        postingDate: Date,
        entryId: Int?,
        family: VATStatusFamily,
        code: String,
        label: String,
        kind: VATKind,
        isSettlementRemainder: Bool,
        originalAmount: Decimal,
        remainingAmount: Decimal
    ) {
        self.sourcePeriod = sourcePeriod
        self.postingDate = postingDate
        self.entryId = entryId
        self.family = family
        self.code = code
        self.label = label
        self.kind = kind
        self.isSettlementRemainder = isSettlementRemainder
        self.originalAmount = originalAmount
        self.remainingAmount = remainingAmount
    }

    public var isFileableRubricCarry: Bool {
        !isSettlementRemainder
            && (
                family == .output
                    || family == .deductible
                    || family == .privateUse
            )
    }
}

public struct VATResidualLedger: Sendable, Codable, Hashable {
    public let lots: [VATResidualLot]

    public init(
        lots: [VATResidualLot]
    ) {
        self.lots = lots
    }

    public var totalRaw: Decimal {
        lots.reduce(0) {
            $0 + $1.remainingAmount
        }
    }

    public var fileableRaw: Decimal {
        lots
            .filter(\.isFileableRubricCarry)
            .reduce(0) {
                $0 + $1.remainingAmount
            }
    }

    public var settlementRemainderRaw: Decimal {
        lots
            .filter(\.isSettlementRemainder)
            .reduce(0) {
                $0 + $1.remainingAmount
            }
    }
}

public enum VATResidualLedgerBuilder {
    public static func buildCarryIn(
        resolvedEntries: [ResolvedEntry],
        chart: CompiledChart,
        targetPeriod: VATPeriod,
        calendar: Calendar,
        businessEntity: BusinessEntity = .vof
    ) -> VATResidualLedger {
        let roots = businessEntity.vatRoots

        let labelByCode = Dictionary(
            uniqueKeysWithValues: chart.nodes.map {
                ($0.codes.code, $0.labels.short)
            }
        )

        var openLots: [MutableVATResidualLot] = []

        let sortedEntries = resolvedEntries.sorted { lhs, rhs in
            let lhsDate = absoluteDate(lhs) ?? Date.distantPast
            let rhsDate = absoluteDate(rhs) ?? Date.distantPast

            if lhsDate != rhsDate {
                return lhsDate < rhsDate
            }

            return (lhs.id ?? Int.max) < (rhs.id ?? Int.max)
        }

        for entry in sortedEntries {
            guard let postingDate = absoluteDate(entry) else {
                continue
            }

            let postingPeriod = period(
                containing: postingDate,
                calendar: calendar
            )

            let annotatedPeriod = entry.vat?.period
            let sourcePeriod = annotatedPeriod ?? postingPeriod

            guard isBefore(
                sourcePeriod,
                targetPeriod
            ) else {
                continue
            }

            let movements = vatMovements(
                entry: entry,
                sourcePeriod: sourcePeriod,
                postingDate: postingDate,
                roots: roots,
                labelByCode: labelByCode
            )

            guard !movements.isEmpty else {
                continue
            }

            if entry.vat?.kind == .settlement {
                let settlementNet = movements.reduce(Decimal(0)) {
                    $0 + $1.amount
                }

                applySettlement(
                    settlementNet,
                    sourcePeriod: sourcePeriod,
                    postingDate: postingDate,
                    entryId: entry.id,
                    movements: movements,
                    openLots: &openLots
                )

                continue
            }

            let kind = entry.vat?.kind ?? .filing

            for movement in movements where movement.amount != 0 {
                openLots.append(
                    MutableVATResidualLot(
                        sourcePeriod: sourcePeriod,
                        postingDate: postingDate,
                        entryId: entry.id,
                        family: movement.family,
                        code: movement.code,
                        label: movement.label,
                        kind: kind,
                        isSettlementRemainder: false,
                        originalAmount: movement.amount,
                        remainingAmount: movement.amount
                    )
                )
            }
        }

        let lots = openLots
            .filter {
                $0.remainingAmount != 0
            }
            .sorted {
                sortLot(lhs: $0, rhs: $1)
            }
            .map {
                $0.frozen
            }

        return VATResidualLedger(
            lots: lots
        )
    }
}

private struct VATLineMovement: Sendable {
    let family: VATStatusFamily
    let code: String
    let label: String
    let amount: Decimal
}

private struct MutableVATResidualLot: Sendable {
    let sourcePeriod: VATPeriod
    let postingDate: Date
    let entryId: Int?
    let family: VATStatusFamily
    let code: String
    let label: String
    let kind: VATKind
    let isSettlementRemainder: Bool
    let originalAmount: Decimal
    var remainingAmount: Decimal

    var frozen: VATResidualLot {
        .init(
            sourcePeriod: sourcePeriod,
            postingDate: postingDate,
            entryId: entryId,
            family: family,
            code: code,
            label: label,
            kind: kind,
            isSettlementRemainder: isSettlementRemainder,
            originalAmount: originalAmount,
            remainingAmount: remainingAmount
        )
    }
}

private extension VATResidualLedgerBuilder {
    static func absoluteDate(
        _ entry: ResolvedEntry
    ) -> Date? {
        guard case .absolute(let postingDate) = entry.date else {
            return nil
        }

        return postingDate
    }

    static func period(
        containing date: Date,
        calendar: Calendar
    ) -> VATPeriod {
        let year = calendar.component(
            .year,
            from: date
        )

        let month = calendar.component(
            .month,
            from: date
        )

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

        return VATPeriod(
            year: year,
            quarter: quarter
        )
    }

    static func isBefore(
        _ lhs: VATPeriod,
        _ rhs: VATPeriod
    ) -> Bool {
        if lhs.year != rhs.year {
            return lhs.year < rhs.year
        }

        return lhs.quarter.rawValue < rhs.quarter.rawValue
    }

    static func vatMovements(
        entry: ResolvedEntry,
        sourcePeriod: VATPeriod,
        postingDate: Date,
        roots: VATRoots,
        labelByCode: [String: String]
    ) -> [VATLineMovement] {
        entry.lines.compactMap { line in
            let code = line.account.code

            guard let family = family(
                for: code,
                roots: roots
            ) else {
                return nil
            }

            let amount = signedRaw(
                line
            )

            guard amount != 0 else {
                return nil
            }

            return VATLineMovement(
                family: family,
                code: code,
                label: labelByCode[code] ?? code,
                amount: amount
            )
        }
    }

    static func family(
        for code: String,
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

    static func signedRaw(
        _ line: ResolvedLine
    ) -> Decimal {
        line.direction == .debit
            ? line.amount
            : -line.amount
    }

    static func applySettlement(
        _ settlementNet: Decimal,
        sourcePeriod: VATPeriod,
        postingDate: Date,
        entryId: Int?,
        movements: [VATLineMovement],
        openLots: inout [MutableVATResidualLot]
    ) {
        var remainingSettlement = settlementNet

        guard remainingSettlement != 0 else {
            return
        }

        let indexes = openLots.indices
            .filter {
                openLots[$0].sourcePeriod == sourcePeriod
                    && signsAreOpposed(
                        openLots[$0].remainingAmount,
                        remainingSettlement
                    )
            }
            .sorted {
                sortLot(
                    lhs: openLots[$0],
                    rhs: openLots[$1]
                )
            }

        for index in indexes {
            guard remainingSettlement != 0 else {
                break
            }

            let openAmount = openLots[index].remainingAmount

            guard signsAreOpposed(
                openAmount,
                remainingSettlement
            ) else {
                continue
            }

            let appliedAbs = minDecimal(
                DecimalFuncs.absDec(openAmount),
                DecimalFuncs.absDec(remainingSettlement)
            )

            let applied = remainingSettlement > 0
                ? appliedAbs
                : -appliedAbs

            openLots[index].remainingAmount += applied
            remainingSettlement -= applied
        }

        guard remainingSettlement != 0 else {
            return
        }

        let settlementCode = movements.first?.code ?? "settlement"
        let settlementLabel = movements.first?.label ?? "Settlement remainder"

        openLots.append(
            MutableVATResidualLot(
                sourcePeriod: sourcePeriod,
                postingDate: postingDate,
                entryId: entryId,
                family: .payableFallback,
                code: settlementCode,
                label: settlementLabel,
                kind: .settlement,
                isSettlementRemainder: true,
                originalAmount: remainingSettlement,
                remainingAmount: remainingSettlement
            )
        )
    }

    static func signsAreOpposed(
        _ lhs: Decimal,
        _ rhs: Decimal
    ) -> Bool {
        (lhs < 0 && rhs > 0)
            || (lhs > 0 && rhs < 0)
    }

    static func minDecimal(
        _ lhs: Decimal,
        _ rhs: Decimal
    ) -> Decimal {
        lhs < rhs ? lhs : rhs
    }

    static func sortLot(
        lhs: MutableVATResidualLot,
        rhs: MutableVATResidualLot
    ) -> Bool {
        if lhs.sourcePeriod.year != rhs.sourcePeriod.year {
            return lhs.sourcePeriod.year < rhs.sourcePeriod.year
        }

        if lhs.sourcePeriod.quarter.rawValue != rhs.sourcePeriod.quarter.rawValue {
            return lhs.sourcePeriod.quarter.rawValue < rhs.sourcePeriod.quarter.rawValue
        }

        if lhs.postingDate != rhs.postingDate {
            return lhs.postingDate < rhs.postingDate
        }

        if (lhs.entryId ?? Int.max) != (rhs.entryId ?? Int.max) {
            return (lhs.entryId ?? Int.max) < (rhs.entryId ?? Int.max)
        }

        if lhs.code != rhs.code {
            return lhs.code < rhs.code
        }

        return lhs.family.rawValue < rhs.family.rawValue
    }

    static func sortLot(
        lhs: VATResidualLot,
        rhs: VATResidualLot
    ) -> Bool {
        if lhs.sourcePeriod.year != rhs.sourcePeriod.year {
            return lhs.sourcePeriod.year < rhs.sourcePeriod.year
        }

        if lhs.sourcePeriod.quarter.rawValue != rhs.sourcePeriod.quarter.rawValue {
            return lhs.sourcePeriod.quarter.rawValue < rhs.sourcePeriod.quarter.rawValue
        }

        if lhs.postingDate != rhs.postingDate {
            return lhs.postingDate < rhs.postingDate
        }

        if (lhs.entryId ?? Int.max) != (rhs.entryId ?? Int.max) {
            return (lhs.entryId ?? Int.max) < (rhs.entryId ?? Int.max)
        }

        if lhs.code != rhs.code {
            return lhs.code < rhs.code
        }

        return lhs.family.rawValue < rhs.family.rawValue
    }
}
