import Foundation

// public struct RGSAssemblerResult: Sendable {
//     public let totalsById: [Int: Decimal]
//     public let kindById: [Int: StatementKind]    // .balance or .income
//     public let sortKeyById: [Int: String]        // "A.B.A010" etc.
//     public let directionById: [Int: Direction]   // debit | credit
//     public let parentById: [Int: Int]            // child -> parent
// }

public struct RGSAssemblerResult: Sendable {
    public let totalsById: [Int: Decimal]
    public let kindById: [Int: StatementKind]
    public let sortKeyById: [Int: String]        // id -> "A.B.A010"
    public let directionById: [Int: Direction]
    public let parentById: [Int: Int]            // (still kept for debugging)
    public let keyToId: [String: Int]            // "A.B.A010" -> id   NEW
    public let nameById: [Int: String]           // node.labels.short   NEW
}

public struct StatementBundle: Sendable {
    public let balance: [RGSPresentationLine]
    public let income:  [RGSPresentationLine]
    public let totalsById: [Int: Decimal]   // for debugging / future use
    
    public init(
        balance: [RGSPresentationLine],
        income: [RGSPresentationLine],
        totalsById: [Int: Decimal]   // for debugging / future use
    ) {
        self.balance = balance
        self.income = income
        self.totalsById = totalsById
    }
}

public enum RGSAssembler {
    public static func assemble(
        chart: CompiledChart,
        trialRows: [TrialBalanceRow],
        cut: AssembleCut,
        omslag: OmslagMode,
        for businessEntity: BusinessEntity = .vof,
        autoClose: Bool = true
    ) throws -> StatementBundle {
        let ch = try chart.ensuringIndex(enrichNodes: true, strict: false)
        guard let index = ch.index else { throw RGSAssemblerError.missingIndex }

        // Build maps + fallbacks
        let maps   = try RGSAssembler.makeMaps(from: ch)
        assertEdgesMatchKeys(maps)

        // --- Auto-close: resolve target nodes (single-code variant) ---
        let targets  = AutoCloseTargets(for: businessEntity)
        let resolved = try targets.resolve(in: index, validateWith: maps)

        // Seed + roll-up
        let seed   = RGSAssembler.seedLeafs(from: trialRows, using: index)
        try assertSeedSumsToZero(seed)

        if !autoClose {
            // ROLLING UP BY SORTINGKEY
            // let totals = RGSAssembler.rollupBySortingKey(
            //     seed    ,  
            //     idToKey :  maps.sortKeyById,
            //     keyToId :  maps.keyToId
            // )

            // ATTEMPT TO ROLL UP BY PARENT BY ID
            let totals = RGSAssembler.rollupAmounts(
                seed,  
                parentById:  maps.parentById
            )

            // Forced inclusions (codes → ids)
            let forcedIds = Set(cut.includeCodes.compactMap { index.byIdentifier[$0] })
            let forcedChain: Set<Int> = cut.includeIntermediates ? Set(forcedIds.flatMap { chainToRoot($0, parentById: maps.parentById) }) : forcedIds

            // Labels by sort-key prefix
            let labels = index.labelByGroupKey

            // Build lines
            let bs = linesFor(
                .balance,
                roll: maps,
                totals: totals,
                labels: labels,
                cut: cut,
                forcedIds: forcedIds,
                forcedChain: forcedChain,
                omslag: omslag
            )

            let is_ = linesFor(
                .income,
                roll: maps,
                totals: totals,
                labels: labels,
                cut: cut,
                forcedIds: forcedIds,
                forcedChain: forcedChain,
                omslag: omslag
            )

            return StatementBundle(balance: bs, income: is_, totalsById: totals)
        } else {
            // Make sure these codes are included in the presentation even if zero
            var localCut = cut
            localCut.includeCodes.append(contentsOf: [resolved.ni.code, resolved.equity.code])
            // --- end auto-close resolve ---

            // --- auto-close overlay (you already have this) ---
            let ni = seed.reduce(into: Decimal(0)) { acc, kv in
                if maps.kindById[kv.key] == .income { acc += kv.value }    // debit - credit
            }
            let manualAtNi     = seed[resolved.ni.id] ?? 0
            let manualAtEquity = seed[resolved.equity.id] ?? 0
            let hasManual = (manualAtNi != 0 || manualAtEquity != 0)

            var seedWithAC = seed
            if !hasManual && ni != 0 {
                seedWithAC[resolved.ni.id,     default: 0] += (-ni) // zero P&L node
                seedWithAC[resolved.equity.id, default: 0] += ( ni) // push into equity
            }

            // --- two rollups: NO overlay for IS, overlay for BS ---
            // var totalsIncome  = RGSAssembler.rollupBySortingKey(seed,        idToKey: maps.sortKeyById, keyToId: maps.keyToId)
            // let totalsBalance = RGSAssembler.rollupBySortingKey(seedWithAC,  idToKey: maps.sortKeyById, keyToId: maps.keyToId)

            // ATTEMPTING PARENT BY ID ROLLUP
            var totalsIncome  = RGSAssembler.rollupAmounts(seed,        parentById: maps.parentById)
            let totalsBalance = RGSAssembler.rollupAmounts(seedWithAC,  parentById: maps.parentById)
            // --- end auto-close overlay ---

            // place NI on the NI node for IS presentation (do NOT invert here)
            if !hasManual && ni != 0 {
                totalsIncome[resolved.ni.id, default: 0] += ni
            }

            // Forced inclusions (codes → ids)
            let forcedIds = Set(localCut.includeCodes.compactMap { index.byIdentifier[$0] })
            let forcedChain: Set<Int> = localCut.includeIntermediates ? Set(forcedIds.flatMap { chainToRoot($0, parentById: maps.parentById) }) : forcedIds

            // Labels by sort-key prefix
            let labels = index.labelByGroupKey

            // Build lines
            let bs = linesFor(
                .balance,
                roll: maps,
                totals: totalsBalance,
                labels: labels,
                cut: localCut,
                forcedIds: forcedIds,
                forcedChain: forcedChain,
                omslag: omslag
            )

            let is_ = linesFor(
                .income,
                roll: maps,
                totals: totalsIncome,
                labels: labels,
                cut: localCut,
                forcedIds: forcedIds,
                forcedChain: forcedChain,
                omslag: omslag
            )

            return StatementBundle(balance: bs, income: is_, totalsById: totalsBalance)
        }
    }

    public static func makeMaps(from chart: CompiledChart) throws -> RGSAssemblerResult {
        let ch = try chart.ensuringIndex(enrichNodes: true, strict: false)
        guard let idx = ch.index else { throw RGSAssemblerError.missingIndex }

        var kindById: [Int: StatementKind] = [:]
        var sortKeyById: [Int: String] = [:]
        var directionById: [Int: Direction] = [:]
        var parentById: [Int: Int] = [:]
        var nameById: [Int: String] = [:]

        for n in ch.nodes {
            if let x = n.xlsx {
                let key = x.cachedSortingKey
                sortKeyById[n.id] = key
                if let pid = x.links.parentId { parentById[n.id] = pid }
            }
            directionById[n.id] = n.direction
            nameById[n.id] = n.labels.short
            if n.codes.code.hasPrefix("B") { kindById[n.id] = .balance }
            else if n.codes.code.hasPrefix("W") { kindById[n.id] = .income }
        }

        return .init(
            totalsById: [:],
            kindById: kindById,
            sortKeyById: sortKeyById,
            directionById: directionById,
            parentById: parentById,
            keyToId: idx.bySortKey,                 // from the index (key -> id)
            nameById: nameById
        )
    }

    public static func seedLeafs(from trial: [TrialBalanceRow],
                                 using index: RGSIndex) -> [Int: Decimal] {
        var byId: [Int: Decimal] = [:]
        for row in trial {
            if let id = index.byIdentifier[row.accountCode] {
                byId[id, default: 0] += row.net
            }
        }
        return byId
    }

    public static func rollupAmounts(
        _ seed: [Int: Decimal],
        parentById: [Int: Int]
    ) -> [Int: Decimal] {
        var totals = seed
        for (leaf, amt) in seed where amt != 0 {
            var cur = leaf
            while let p = parentById[cur] {
                totals[p, default: 0] += amt
                cur = p
            }
        }
        return totals
    }

    /// Deterministic roll-up: climb SortingKey prefixes.
    /// Works even when parentId links are missing or partial.
    public static func rollupBySortingKey(
        _ seed: [Int: Decimal],
        idToKey: [Int: String],
        keyToId: [String: Int]
    ) -> [Int: Decimal] {
        var totals = seed
        for (leafId, amt) in seed where amt != 0 {
            guard let key = idToKey[leafId], !key.isEmpty else { continue }
            var curKey: String? = key
            while let k = curKey {
                // go to parent prefix
                guard let pk = RGSNodeSortingCode(key: k).parentKeyString, !pk.isEmpty else { break }
                if let pid = keyToId[pk] {
                    totals[pid, default: 0] += amt
                    curKey = pk
                } else {
                    // stop if parent prefix not mapped (should be rare)
                    break
                }
            }
        }
        return totals
    }

    public static func present(
        _ amount: Decimal,
        direction: Direction,
        mode: OmslagMode = .apply
    ) -> Decimal {
        guard mode == .apply else { return amount }
        switch direction {
        case .debit:  return amount
        case .credit: return -amount
        }
    }
    
    public static func assertEdgesMatchKeys(_ maps: RGSAssemblerResult) {
        var bad: [(Int,String,String)] = []
        for (child, parent) in maps.parentById {
            guard
                let ck = maps.sortKeyById[child],
                let pk = maps.sortKeyById[parent],
                let cpk = RGSNodeSortingCode(key: ck).parentKeyString
            else { continue }
            if cpk != pk {
                bad.append((child, ck, pk))
            }
        }
        if !bad.isEmpty {
            fputs("RGS edge/key mismatches: \(bad.count)\n", stderr)
            for (id, ck, pk) in bad.prefix(20) {
                fputs("  id=\(id) childKey='\(ck)' parentKey='\(pk)'\n", stderr)
            }
        }
    }

    @inline(__always)
    public static func assertSeedSumsToZero(_ seed: [Int: Decimal]) throws {
        let sum = seed.values.reduce(0, +)
        if sum != 0 { throw RGSAssemblerError.seedTotalsNotZero(sum) }
    }
}
