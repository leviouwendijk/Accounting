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
        // assertEdgesMatchKeys(maps)

        // --- Auto-close: resolve target nodes (single-code variant) ---
        let targets  = AutoCloseTargets(for: businessEntity)
        let resolved = try targets.resolve(in: index, validateWith: maps)

        // Seed + roll-up
        let seed   = RGSAssembler.seedLeafs(
            from: trialRows,
            using: index
        )
        try assertSeedSumsToZero(seed)

        // Entity-aware seed (entity dimension preserved)
        let seedAE = RGSAssembler.seedLeafsAE(
            from: trialRows,
            using: index
        ) // or: { $0.entityId }

        if !autoClose {
            return try assembleNoAutoClose(
                chart: ch,
                index: index,
                maps: maps,
                cut: cut,
                omslag: omslag,
                seed: seed,
                seedAE: seedAE
            )
        } else {
            let ac = (
                niId: resolved.ni.id,
                niCode: resolved.ni.code,
                eqId: resolved.equity.id,
                eqCode: resolved.equity.code
            )
            return try assembleWithAutoClose(
                chart: ch,
                index: index,
                maps: maps,
                cut: cut,
                omslag: omslag,
                seed: seed,
                seedAE: seedAE,
                autoCloseTargets: ac
            )
        }
    }

    @inline(__always)
    public static func assembleNoAutoClose(
        chart: CompiledChart,
        index: RGSIndex,
        maps: RGSAssemblerResult,
        cut: AssembleCut,
        omslag: OmslagMode,
        seed: [Int: Decimal],
        seedAE: [AccEntKey: Decimal]
    ) throws -> StatementBundle {
        // Hierarchy rollup (entity-preserving), then collapse for presentation
        let totalsAE    = RGSAssembler.rollupByAccountPreservingEntity(seedAE, parentById: maps.parentById)
        let totalsPlain = RGSAssembler.collapseEntityDimension(totalsAE)

        // Forced inclusions (codes → ids)
        let (forcedIds, forcedChain) = makeForcedSets(index: index, cut: cut, parentById: maps.parentById)

        // Labels by sort-key prefix
        let labels = index.labelByGroupKey

        // Build lines
        let bs = linesFor(
            .balance,
            roll: maps,
            totals: totalsPlain,
            labels: labels,
            cut: cut,
            forcedIds: forcedIds,
            forcedChain: forcedChain,
            omslag: omslag
        )

        let is_ = linesFor(
            .income,
            roll: maps,
            totals: totalsPlain,
            labels: labels,
            cut: cut,
            forcedIds: forcedIds,
            forcedChain: forcedChain,
            omslag: omslag
        )

        // Optional entity breakdown (account → entity → amount)
        var breakdown: EntityBreakdown? = nil
        do {
            var byAccount: [Int: [Int?: Decimal]] = [:]
            for (k, v) in totalsAE where v != 0 {
                byAccount[k.accountId, default: [:]][k.entityId, default: 0] += v
            }
            breakdown = .init(byAccount: byAccount)
        }

        // Bundle + analytics
        let bundle = StatementBundle(
            balance: bs,
            income: is_,
            totalsById: totalsPlain,
            entity: breakdown
        )
        let analytics = try makeAnalytics(chart: chart, bundle: bundle, omslag: omslag)

        return StatementBundle(
            balance: bs,
            income: is_,
            totalsById: totalsPlain,
            entity: breakdown,
            analytics: analytics
        )
    }

    @inline(__always)
    public static func assembleWithAutoClose(
        chart: CompiledChart,
        index: RGSIndex,
        maps: RGSAssemblerResult,
        cut: AssembleCut,
        omslag: OmslagMode,
        seed: [Int: Decimal],
        seedAE: [AccEntKey: Decimal],
        autoCloseTargets: (niId: Int, niCode: String, eqId: Int, eqCode: String)
    ) throws -> StatementBundle {
        // Make sure these codes are included in the presentation even if zero
        var localCut = cut

        localCut.includeCodes.append(
            contentsOf: [
                autoCloseTargets.niCode,
                autoCloseTargets.eqCode
            ]
        )

        // --- auto-close overlay ---
        let ni = seed.reduce(into: Decimal(0)) { acc, kv in
            if maps.kindById[kv.key] == .income { acc += kv.value }
        }

        // Detect real (window) manual postings at NI/equity
        let manualAtNi     = seed[autoCloseTargets.niId] ?? 0
        let manualAtEquity = seed[autoCloseTargets.eqId] ?? 0
        let hasManual      = (manualAtNi != 0 || manualAtEquity != 0)

        // Warn (but keep existing suppression behavior)
        if ni != 0 && hasManual {
            fputs(
                "warning: auto-close NI overlay present but manual postings detected at "
                    + "\(autoCloseTargets.niCode)=\(manualAtNi) and/or \(autoCloseTargets.eqCode)=\(manualAtEquity); "
                    + "overlay suppressed for this period.\n",
                stderr
            )
        }

        var seedWithAC = seed
        if !hasManual && ni != 0 {
            seedWithAC[autoCloseTargets.niId, default: 0] += (-ni) // zero P&L node
            seedWithAC[autoCloseTargets.eqId, default: 0] += ( ni) // push into equity
        }

        // Income (IS): compute from plain seed; add NI as a rolled patch so parents see it
        var totalsIncome = RGSAssembler.rollupAmounts(
            seed,
            parentById: maps.parentById
        )

        if !hasManual && ni != 0 {
            let niPatch = RGSAssembler.rollupAmounts(
                [autoCloseTargets.niId: ni],
                parentById: maps.parentById
            )
            for (k, v) in niPatch where v != 0 {
                totalsIncome[k, default: 0] += v
            }
        }

        // Balance (BS): use overlayed seed
        let totalsBalance = RGSAssembler.rollupAmounts(
            seedWithAC,
            parentById: maps.parentById
        )
        // --- end auto-close overlay ---

        // Forced inclusions (codes → ids)
        let (forcedIds, forcedChain) = makeForcedSets(
            index: index,
            cut: localCut,
            parentById: maps.parentById
        )

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

        // Optional entity breakdown for IS (from entity-preserving rollup)
        var breakdown: EntityBreakdown? = nil
        do {
            let totalsAE_Income = RGSAssembler.rollupByAccountPreservingEntity(
                seedAE, 
                parentById: maps.parentById
            )
            var byAccount: [Int: [Int?: Decimal]] = [:]
            for (k, v) in totalsAE_Income where v != 0 {
                byAccount[k.accountId, default: [:]][k.entityId, default: 0] += v
            }
            breakdown = .init(byAccount: byAccount)
        }

        // Bundle + analytics (analytics should reflect the BS totals we present with AC)
        let bundle = StatementBundle(
            balance: bs,
            income: is_,
            totalsById: totalsBalance,
            entity: breakdown
        )

        let analytics = try makeAnalytics(
            chart: chart,
            bundle: bundle,
            omslag: omslag
        )

        return StatementBundle(
            balance: bs,
            income: is_,
            totalsById: totalsBalance,
            entity: breakdown,
            analytics: analytics
        )
    }

    @inline(__always)
    public static func makeForcedSets(
        index: RGSIndex,
        cut: AssembleCut,
        parentById: [Int: Int]
    ) -> (forcedIds: Set<Int>, forcedChain: Set<Int>) {
        let forcedIds = Set(cut.includeCodes.compactMap { index.byIdentifier[$0] })
        let forcedChain: Set<Int> = cut.includeIntermediates ? Set(forcedIds.flatMap { chainToRoot($0, parentById: parentById) }) : forcedIds
        return (forcedIds, forcedChain)
    }

    @inline(__always)
    public static func makeAnalytics(
        chart: CompiledChart,
        bundle: StatementBundle,
        omslag: OmslagMode
    ) throws -> BundleAnalytics {
        let l2 = try RGSAssembler.makeL2Buckets(chart: chart, defaultEquityCode: "BEiv")
        let totals = try RGSAssembler.presentedTotalsByL2(chart: chart, bundle: bundle, buckets: l2, omslag: omslag)
        return BundleAnalytics(l2Buckets: l2, l2Totals: totals)
    }
}
