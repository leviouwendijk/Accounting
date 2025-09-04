import Foundation

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

    public static func makeMaps(from ch: CompiledChart) throws -> RGSAssemblerResult {
        guard let index = ch.index else { throw RGSAssemblerError.missingIndex }

        let nodes = ch.nodes

        // sortingkey for order only 
        var sortKeyById: [Int:String] = [:]
        for n in nodes {
            let key = n.xlsx?.sorting.key ?? n.codes.code
            sortKeyById[n.id] = key
        }

        let directionById = Dictionary(uniqueKeysWithValues: nodes.compactMap { n in
            n.direction.map { (n.id, $0) }
        })

        let kindById: [Int: StatementKind] = Dictionary(uniqueKeysWithValues: nodes.map { n in
            (n.id, (n.side == .balance ? .balance : .income))
        })

        let keyToId = index.bySortKey    // existing compiled index

        // parent by rgs identifier
        let hier = RGSIdentifierHierarchy.build(from: nodes)
        let parentById: [Int:Int] = Dictionary(uniqueKeysWithValues:
            hier.parentById.compactMap { (child, parent) in parent.map { (child, $0) } }
        )

        return RGSAssemblerResult(
            totalsById: [:],                    // filled later
            kindById: kindById,
            sortKeyById: sortKeyById,
            directionById: directionById,
            parentById: parentById,
            keyToId: keyToId,
            nameById: Dictionary(uniqueKeysWithValues: nodes.map{ ($0.id, $0.labels.short) })
        )
    }
}
