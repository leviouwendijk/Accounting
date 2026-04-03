import Foundation

public enum VATStatusBuilder {
    public static func build(
        resolvedEntries: [ResolvedEntry],
        chart: CompiledChart,
        title: String = "VAT status",
        period: PeriodWindow? = nil,
        tolerance: Decimal = 0.01,
        calendar: Calendar,
        businessEntity: BusinessEntity = .vof
    ) throws -> VATStatusReport {
        let roots = businessEntity.vatRoots
        let maps = try RGSAssembler.makeMaps(from: chart)

        let idByCode = Dictionary(
            uniqueKeysWithValues: chart.nodes.map { ($0.codes.code, $0.id) }
        )

        let codeById = Dictionary(
            uniqueKeysWithValues: chart.nodes.map { ($0.id, $0.codes.code) }
        )

        // The selected period is no longer treated as the whole computation window.
        // Instead, status is backsolved from inception through the selected end.
        let historyEnd = period?.to

        let selectedPeriods = period.map {
            Set(periodsOverlapping($0, calendar: calendar))
        } ?? []

        let includedDates = resolvedEntries.compactMap { entry -> Date? in
            guard case .absolute(let postingDate) = entry.date else {
                return nil
            }

            guard shouldIncludeHistoryPosting(
                postingDate: postingDate,
                through: historyEnd
            ) else {
                return nil
            }

            return postingDate
        }

        let earliestIncludedDate = includedDates.min()
        let latestIncludedDate = includedDates.max()

        var ordinaryByPeriod: [VATPeriod: StatusBreakdown] = [:]
        var ordinaryTreeSeedByPeriod: [VATPeriod: FamilySeed] = [:]
        var correctionsByPeriod: [VATPeriod: Decimal] = [:]
        var taggedEntriesByPeriod: [VATPeriod: [VATAuditEntry]] = [:]

        for entry in resolvedEntries {
            guard case .absolute(let postingDate) = entry.date else {
                continue
            }

            guard shouldIncludeHistoryPosting(
                postingDate: postingDate,
                through: historyEnd
            ) else {
                continue
            }

            let postingQuarter = vatPeriod(
                for: postingDate,
                calendar: calendar
            )

            let annotation = entry.vat

            if shouldCountInOrdinaryLedger(annotation: annotation) {
                let breakdown = ordinaryBreakdown(
                    for: entry,
                    roots: roots
                )

                if !breakdown.isZero {
                    ordinaryByPeriod[postingQuarter, default: .zero] += breakdown
                }

                let treeSeed = ordinaryBreakdownTreeSeed(
                    for: entry,
                    roots: roots,
                    idByCode: idByCode
                )

                if !treeSeed.isEmpty {
                    mergeOrdinaryTreeSeed(
                        into: &ordinaryTreeSeedByPeriod[postingQuarter, default: [:]],
                        adding: treeSeed
                    )
                }
            }

            guard let annotation else {
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
            .union(ordinaryTreeSeedByPeriod.keys)
            .union(correctionsByPeriod.keys)
            .union(taggedEntriesByPeriod.keys)

        periods.formUnion(selectedPeriods)

        if let earliestIncludedDate,
           let latestIncludedDate {
            periods.formUnion(
                contiguousPeriods(
                    from: earliestIncludedDate,
                    through: latestIncludedDate,
                    calendar: calendar
                )
            )
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
                let ordinaryTree = makeOrdinaryFamilyBreakdowns(
                    ordinaryTreeSeedByPeriod[periodKey] ?? [:],
                    roots: roots,
                    maps: maps,
                    codeById: codeById
                )

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

                let quarterMovement = ordinary.net + correctionsNet
                if quarterMovement != 0 {
                    carryBag[periodKey, default: 0] += quarterMovement
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
                    ordinaryBreakdownTree: ordinaryTree,
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
    typealias FamilySeed = [VATStatusFamily: [Int: Decimal]]

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
    static func shouldIncludeHistoryPosting(
        postingDate: Date,
        through historyEnd: Date?
    ) -> Bool {
        guard let historyEnd else {
            return true
        }

        return postingDate <= historyEnd
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

            // Native BS polarity for status:
            // debit = positive, credit = negative
            let effect = signedRaw(line)

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

    static func ordinaryBreakdownTreeSeed(
        for entry: ResolvedEntry,
        roots: VATRoots,
        idByCode: [String: Int]
    ) -> FamilySeed {
        var out: FamilySeed = [:]

        for line in entry.lines {
            let code = line.account.code

            guard let family = classifyStatusFamily(
                code,
                roots: roots
            ) else {
                continue
            }

            guard let id = idByCode[code] else {
                continue
            }

            let effect = signedRaw(line)
            guard effect != 0 else {
                continue
            }

            out[family, default: [:]][id, default: 0] += effect
        }

        return out
    }

    static func mergeOrdinaryTreeSeed(
        into lhs: inout FamilySeed,
        adding rhs: FamilySeed
    ) {
        for (family, seed) in rhs {
            for (id, amount) in seed {
                lhs[family, default: [:]][id, default: 0] += amount
            }
        }
    }

    static func makeOrdinaryFamilyBreakdowns(
        _ seedByFamily: FamilySeed,
        roots: VATRoots,
        maps: RGSAssemblerResult,
        codeById: [Int: String]
    ) -> [VATStatusFamilyBreakdown] {
        let families = seedByFamily.keys.sorted {
            familySortOrder($0) < familySortOrder($1)
        }

        return families.compactMap { family in
            guard let seed = seedByFamily[family],
                  !seed.isEmpty
            else {
                return nil
            }

            let rolled = RGSAssembler.rollupAmounts(
                seed,
                parentById: maps.parentById
            )

            let activeIDs = Set(
                rolled.compactMap { key, value in
                    value != 0 ? key : nil
                }
            )

            guard !activeIDs.isEmpty else {
                return nil
            }

            let rootIDs = familyRootIDs(
                family: family,
                activeIDs: activeIDs,
                roots: roots,
                maps: maps,
                codeById: codeById
            )

            let childrenByParent = activeChildrenByParent(
                activeIDs: activeIDs,
                parentById: maps.parentById
            )

            let nodes = makeStatusTreeNodes(
                from: rootIDs,
                rolled: rolled,
                childrenByParent: childrenByParent,
                maps: maps,
                codeById: codeById
            )

            return VATStatusFamilyBreakdown(
                family: family,
                amount: seed.values.reduce(0, +),
                nodes: nodes
            )
        }
    }

    @inline(__always)
    static func familySortOrder(
        _ family: VATStatusFamily
    ) -> Int {
        switch family {
        case .output:
            return 0

        case .deductible:
            return 1

        case .privateUse:
            return 2

        case .receivable:
            return 3

        case .payableFallback:
            return 4
        }
    }

    @inline(__always)
    static func prefixes(
        for family: VATStatusFamily,
        roots: VATRoots
    ) -> [String] {
        switch family {
        case .output:
            return roots.outputCodes

        case .deductible:
            return roots.deductibleCodes

        case .privateUse:
            return roots.privateUseCodes

        case .receivable:
            return roots.receivableCodes

        case .payableFallback:
            return roots.payableCodes
        }
    }

    static func familyRootIDs(
        family: VATStatusFamily,
        activeIDs: Set<Int>,
        roots: VATRoots,
        maps: RGSAssemblerResult,
        codeById: [Int: String]
    ) -> [Int] {
        let familyPrefixes = prefixes(
            for: family,
            roots: roots
        )

        let matchingRoots = activeIDs.filter { id in
            guard let code = codeById[id] else {
                return false
            }

            guard matchesAnyPrefix(
                code,
                prefixes: familyPrefixes,
                excluded: roots.excludedCodes
            ) else {
                return false
            }

            guard let parentId = maps.parentById[id],
                  let parentCode = codeById[parentId]
            else {
                return true
            }

            return !matchesAnyPrefix(
                parentCode,
                prefixes: familyPrefixes,
                excluded: roots.excludedCodes
            )
        }

        if !matchingRoots.isEmpty {
            return sortStatusIDs(
                Array(matchingRoots),
                maps: maps,
                codeById: codeById
            )
        }

        let fallbackRoots = activeIDs.filter { id in
            guard let parentId = maps.parentById[id] else {
                return true
            }

            return !activeIDs.contains(parentId)
        }

        return sortStatusIDs(
            Array(fallbackRoots),
            maps: maps,
            codeById: codeById
        )
    }

    static func activeChildrenByParent(
        activeIDs: Set<Int>,
        parentById: [Int: Int]
    ) -> [Int: [Int]] {
        var out: [Int: [Int]] = [:]

        for id in activeIDs {
            guard let parentId = parentById[id],
                  activeIDs.contains(parentId)
            else {
                continue
            }

            out[parentId, default: []].append(id)
        }

        return out
    }

    static func makeStatusTreeNodes(
        from rootIDs: [Int],
        rolled: [Int: Decimal],
        childrenByParent: [Int: [Int]],
        maps: RGSAssemblerResult,
        codeById: [Int: String]
    ) -> [VATStatusTreeNode] {
        let orderedIDs = sortStatusIDs(
            rootIDs,
            maps: maps,
            codeById: codeById
        )

        return orderedIDs.compactMap { id in
            let amount = rolled[id] ?? 0
            guard amount != 0 else {
                return nil
            }

            let code = codeById[id] ?? "node#\(id)"
            let label = maps.nameById[id] ?? code

            let children = makeStatusTreeNodes(
                from: childrenByParent[id] ?? [],
                rolled: rolled,
                childrenByParent: childrenByParent,
                maps: maps,
                codeById: codeById
            )

            return VATStatusTreeNode(
                id: id,
                code: code,
                label: label,
                amount: amount,
                children: children
            )
        }
    }

    static func sortStatusIDs(
        _ ids: [Int],
        maps: RGSAssemblerResult,
        codeById: [Int: String]
    ) -> [Int] {
        ids.sorted { lhs, rhs in
            let lhsKey = maps.sortKeyById[lhs] ?? codeById[lhs] ?? ""
            let rhsKey = maps.sortKeyById[rhs] ?? codeById[rhs] ?? ""

            if lhsKey != rhsKey {
                return lhsKey < rhsKey
            }

            return lhs < rhs
        }
    }

    static func auditMovement(
        for entry: ResolvedEntry,
        roots: VATRoots
    ) -> (payable: Decimal, receivable: Decimal) {
        var payable: Decimal = 0
        var receivable: Decimal = 0

        for line in entry.lines {
            let code = line.account.code
            let raw = signedRaw(line)

            if isPayableVATCode(
                code,
                roots: roots
            ) {
                payable += raw
            }

            if isReceivableVATCode(
                code,
                roots: roots
            ) {
                receivable += raw
            }
        }

        return (
            payable,
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

        // Native BS polarity:
        // debit settlement = paid
        // credit settlement = received
        if netMovement > 0 {
            return .paid
        }

        if netMovement < 0 {
            return .received
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

        let netMovement = movement.payable + movement.receivable
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

        return contiguousPeriods(
            from: start,
            through: end,
            calendar: calendar
        )
    }

    static func contiguousPeriods(
        from start: Date,
        through end: Date,
        calendar: Calendar
    ) -> [VATPeriod] {
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
