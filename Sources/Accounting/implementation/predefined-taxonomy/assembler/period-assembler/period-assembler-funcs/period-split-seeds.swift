import Foundation

// public extension PeriodAssembler {
//     /// Core: IS from window; BS = OpeningBeg(from pre-window) + YTD(with AC overlay); NI overlay from YTD (suppressed if manual).
//     @inline(__always)
//     static func assembleSplitSeeds(
//         chart: CompiledChart,
//         tbIncomeWindow: [TrialBalanceRow],
//         // tbBalanceYTD: [TrialBalanceRow],
//         tbBalanceWindow: [TrialBalanceRow],
//         tbOverlayForNI: [TrialBalanceRow],
//         tbPreWindowForOpening: [TrialBalanceRow]?,   // ← NEW: pre-window seed for *Beg mapping
//         cut: AssembleCut,
//         omslag: OmslagMode,
//         entity: BusinessEntity
//     ) throws -> StatementBundle {

//         // maps + index
//         let ch  = try chart.ensuringIndex(enrichNodes: true, strict: false)
//         guard let index = ch.index else { throw RGSAssemblerError.missingIndex }

//         let maps = try RGSAssembler.makeMaps(from: ch)

//         // resolve NI/Equity (with kind validation)
//         let targets  = AutoCloseTargets(for: entity)
//         let resolved = try targets.resolve(in: index, validateWith: maps)

//         let routing = entity.periodOpeningRouting

//         // seeds
//         let seedIncome  = RGSAssembler.seedLeafs(from: tbIncomeWindow,  using: index)
//         // let seedYTD     = RGSAssembler.seedLeafs(from: tbBalanceYTD,    using: index)
//         let seedWinBal  = RGSAssembler.seedLeafs(from: tbBalanceWindow, using: index)
//         let seedOverlay = RGSAssembler.seedLeafs(from: tbOverlayForNI,  using: index)
//         try RGSAssembler.assertSeedSumsToZero(seedIncome)
//         // try RGSAssembler.assertSeedSumsToZero(seedYTD)
//         try RGSAssembler.assertSeedSumsToZero(seedWinBal)
//         try RGSAssembler.assertSeedSumsToZero(seedOverlay)

//         let seedAEWin = RGSAssembler.seedLeafsAE(from: tbIncomeWindow, using: index)  // account×entity → amount  :contentReference[oaicite:4]{index=4}

//         // OpeningBeg from pre-window → map to "<L4>Beg" when present (balance accounts only)
//         let seedOpening: [Int: Decimal] = {
//             guard let tbHist = tbPreWindowForOpening, !tbHist.isEmpty else { return [:] }
//             // return RGSAssembler.openingBegSeed(from: tbHist, chart: ch, index: index, maps: maps)
//             return RGSAssembler.openingBegSeed(
//                 from: tbHist,
//                 chart: ch,
//                 index: index,
//                 maps: maps,
//                 routing: routing
//             )
//         }()

//         // Base BS seed = OpeningBeg + YTD
//         var seedBalance = seedOpening
//         // for (k, v) in seedYTD { seedBalance[k, default: 0] += v }
//         for (k, v) in seedWinBal { seedBalance[k, default: 0] += v }


//         // NI overlay from overlay seed (normally YTD), unless manual postings exist
//         let niOverlay = seedOverlay.reduce(into: Decimal(0)) { acc, kv in
//             if maps.kindById[kv.key] == .income { acc += kv.value }
//         }

//         // let hasManual = (seedBalance[resolved.ni.id] ?? 0) != 0 || (seedBalance[resolved.equity.id] ?? 0) != 0
//         let hasManual = false

//         if !hasManual && niOverlay != 0 {
//             seedBalance[resolved.ni.id,     default: 0] += (-niOverlay)
//             seedBalance[resolved.equity.id, default: 0] += ( niOverlay)
//         }

//         var totalsIncome  = RGSAssembler.rollupAmounts(seedIncome,  parentById: maps.parentById)
//         let totalsBalance = RGSAssembler.rollupAmounts(seedBalance, parentById: maps.parentById)

//         let niWindow = seedIncome.reduce(into: Decimal(0)) { acc, kv in
//             if maps.kindById[kv.key] == .income { acc += kv.value }
//         }
//         if niWindow != 0 { totalsIncome[resolved.ni.id, default: 0] += niWindow }

//         // Force NI + Equity visible (like RGSAssembler.assemble(autoClose: true))
//         var localCut = cut
//         localCut.includeCodes.append(contentsOf: [resolved.ni.code, resolved.equity.code])

//         // Presentation lines
//         let forcedIds = Set(localCut.includeCodes.compactMap { index.byIdentifier[$0] })
//         let forcedChain: Set<Int> = localCut.includeIntermediates ? Set(forcedIds.flatMap { chainToRoot($0, parentById: maps.parentById) }) : forcedIds
//         let labels = index.labelByGroupKey

//         let bs = linesFor(.balance, roll: maps, totals: totalsBalance, labels: labels,
//                           cut: localCut, forcedIds: forcedIds, forcedChain: forcedChain, omslag: omslag)
//         let is_ = linesFor(.income,  roll: maps, totals: totalsIncome,  labels: labels,
//                           cut: localCut, forcedIds: forcedIds, forcedChain: forcedChain, omslag: omslag)

//         // -------- entity breakdown (like classic assembler) --------
//         // Roll up the window seed with entity retained, then bucket by account id.
//         let totalsAE_Income = RGSAssembler.rollupByAccountPreservingEntity(seedAEWin, parentById: maps.parentById) // :contentReference[oaicite:7]{index=7}
//         var byAccount: [Int: [Int?: Decimal]] = [:]
//         for (k, v) in totalsAE_Income where v != 0 {
//             byAccount[k.accountId, default: [:]][k.entityId, default: 0] += v
//         }
//         let breakdown = EntityBreakdown(byAccount: byAccount)  // :contentReference[oaicite:8]{index=8}
//         // -----------------------------------------------------------

//         // Optional analytics (same as classic assembler)
//         let bundle = StatementBundle(balance: bs, income: is_, totalsById: totalsBalance, entity: breakdown)
//         let analytics = try RGSAssembler.makeAnalytics(chart: chart, bundle: bundle, omslag: omslag) // :contentReference[oaicite:9]{index=9}

//         return StatementBundle(
//             balance: bs,
//             income: is_,
//             totalsById: totalsBalance,
//             entity: breakdown,
//             analytics: analytics
//         )
//     }
// }

// new version;

public extension PeriodAssembler {
    /// IS from window; BS = OpeningBeg(from pre-window) + WINDOW; NI overlay from same source.
    @inline(__always)
    static func assembleSplitSeeds(
        chart: CompiledChart,
        tbIncomeWindow: [TrialBalanceRow],
        tbBalanceWindow: [TrialBalanceRow],          // ← WINDOW movements (use YTD only when you choose range-to-date at the call-site)
        tbOverlayForNI: [TrialBalanceRow],           // ← typically WINDOW (or YTD if you present YTD)
        tbPreWindowForOpening: [TrialBalanceRow]?,   // ← pre-window seed for *Beg mapping (+ pre-window NI injection inside helper)
        cut: AssembleCut,
        omslag: OmslagMode,
        entity: BusinessEntity,
        // ownership split for “Aandeel in de overwinst” + optional per-row entity mapper
        ownershipSlices: [OwnershipSlice] = [],
        entityIdOnRow: (TrialBalanceRow) -> Int? = { _ in nil }
    ) throws -> StatementBundle {

        // maps + index
        let ch  = try chart.ensuringIndex(enrichNodes: true, strict: false)
        guard let index = ch.index else { throw RGSAssemblerError.missingIndex }
        let maps = try RGSAssembler.makeMaps(from: ch)

        // Resolve NI/Equity targets for this BusinessEntity
        let targets  = entity.autoCloseTargets()
        guard
            let niId  = index.byIdentifier[targets.netIncomeCode],
            let eqId_ = index.byIdentifier[targets.retainedEarningsCode]
        else { throw RGSAssemblerError.missingIndex }

        // Ensure equity overlay goes to a non-Beg container
        let codeById: [Int:String] = Dictionary(uniqueKeysWithValues: ch.nodes.map { ($0.id, $0.codes.code) })
        @inline(__always) func isBeg(_ id: Int) -> Bool { (codeById[id] ?? "").hasSuffix("Beg") }
        let equityTargetId: Int = isBeg(eqId_) ? (maps.parentById[eqId_] ?? eqId_) : eqId_

        // Seeds (plain)
        let seedIncome  = RGSAssembler.seedLeafs(from: tbIncomeWindow,  using: index)
        let seedWinBal  = RGSAssembler.seedLeafs(from: tbBalanceWindow, using: index)
        let seedOverlay = RGSAssembler.seedLeafs(from: tbOverlayForNI,  using: index)
        try RGSAssembler.assertSeedSumsToZero(seedIncome)
        try RGSAssembler.assertSeedSumsToZero(seedWinBal)
        try RGSAssembler.assertSeedSumsToZero(seedOverlay)

        // Opening (plain) → routed to Beg (your helper also injects pre-window NI into equity opening)
        let seedOpeningPlain: [Int: Decimal] = {
            guard let tbHist = tbPreWindowForOpening, !tbHist.isEmpty else { return [:] }
            return RGSAssembler.openingBegSeed(
                from: tbHist,
                chart: ch, index: index, maps: maps,
                routing: entity.periodOpeningRouting
            )
        }()

        // Base BS seed = Opening + WINDOW movements
        var seedBalance = seedOpeningPlain
        for (k, v) in seedWinBal { seedBalance[k, default: 0] += v }

        // NI overlay from the same source you present (typically WINDOW)
        let niOverlay = seedOverlay.reduce(into: Decimal(0)) { acc, kv in
            if maps.kindById[kv.key] == .income { acc += kv.value }
        }

        // Soft suppression: only suppress if WINDOW has manual postings at NI target
        let manualAtNiWin = seedWinBal[niId] ?? 0
        if niOverlay != 0 && manualAtNiWin == 0 {
            seedBalance[niId,           default: 0] += (-niOverlay) // zero P&L node
            seedBalance[equityTargetId, default: 0] += ( niOverlay) // push into equity container (non-Beg)
        }

        // Roll up by the real hierarchy
        var totalsIncome  = RGSAssembler.rollupAmounts(seedIncome,  parentById: maps.parentById)
        let totalsBalance = RGSAssembler.rollupAmounts(seedBalance, parentById: maps.parentById)

        // // Put period NI onto IS NI line (presentation)
        // let niWindow = seedIncome.reduce(into: Decimal(0)) { acc, kv in
        //     if maps.kindById[kv.key] == .income { acc += kv.value }
        // }
        // if niWindow != 0 { totalsIncome[niId, default: 0] += niWindow }

        // Put period NI onto IS NI line (presentation) — rolled patch so parents include it
        let niWindow = seedIncome.reduce(into: Decimal(0)) { acc, kv in
            if maps.kindById[kv.key] == .income { acc += kv.value }
        }
        if niWindow != 0 {
            let niPatch = RGSAssembler.rollupAmounts([niId: niWindow],
                                                     parentById: maps.parentById)
            for (k, v) in niPatch where v != 0 {
                totalsIncome[k, default: 0] += v
            }
        }

        // -------- Entity breakdown (Balance) with ownership split on profit-share --------
        var breakdown: EntityBreakdown? = nil
        do {
            // AE Opening (routes Beg and splits “Aandeel in de overwinst” by ownershipSlices)
            var seedOpeningAE: [AccEntKey: Decimal] = [:]
            if let tbHist = tbPreWindowForOpening, !tbHist.isEmpty {
                seedOpeningAE = RGSAssembler.openingBegSeedAE(
                    from: tbHist,
                    chart: ch, index: index, maps: maps,
                    routing: entity.periodOpeningRouting,
                    profitShareCode: entity.profitShareCode,   // e.g. BEivKapOndAow
                    ownershipSlices: ownershipSlices,
                    entityIdOnRow: entityIdOnRow
                )
            }

            // AE WINDOW movements
            let seedWinBalAE = RGSAssembler.seedLeafsAE(from: tbBalanceWindow, using: index, entityId: entityIdOnRow)

            // Base = Opening(AE) + WINDOW(AE)
            var seedBalanceAE = seedOpeningAE
            for (k, v) in seedWinBalAE { seedBalanceAE[k, default: 0] += v }

            // NI overlay (AE) — push to equity/NI in nil-entity bucket (unless you want to apportion, later)

            // --- AE NI overlay: allocate equity overlay by ownership slices (or nil-entity fallback)
            if niOverlay != 0 && manualAtNiWin == 0 {
                // If you did NOT already overlay the plain (non-AE) seed earlier, uncomment these two lines:
                // seedBalance[niId,           default: 0] += (-niOverlay)
                // seedBalance[equityTargetId, default: 0] += ( niOverlay)

                if ownershipSlices.isEmpty {
                    // No ownership info → dump to unassigned bucket
                    seedBalanceAE[AccEntKey(equityTargetId, nil), default: 0] += niOverlay
                } else {
                    // Split overlay across owners by percentage
                    for s in ownershipSlices where s.percent != 0 {
                        seedBalanceAE[AccEntKey(equityTargetId, s.entityId), default: 0] += (niOverlay * s.percent)
                    }
                }

                // Zero the NI node in AE space (keep in nil-entity bucket)
                seedBalanceAE[AccEntKey(niId, nil), default: 0] -= niOverlay
            }

            // Roll up preserving entity
            let totalsAE_Balance = RGSAssembler.rollupByAccountPreservingEntity(
                seedBalanceAE, parentById: maps.parentById
            )

            // Project AE → breakdown dictionary (account → entity → amount)
            var byAccount: [Int: [Int?: Decimal]] = [:]
            for (k, v) in totalsAE_Balance where v != 0 {
                byAccount[k.accountId, default: [:]][k.entityId, default: 0] += v
            }
            breakdown = .init(byAccount: byAccount)
        }

        // Force NI + Equity visible
        var localCut = cut
        localCut.includeCodes.append(contentsOf: [targets.netIncomeCode, targets.retainedEarningsCode])

        // Presentation lines
        let forcedIds = Set(localCut.includeCodes.compactMap { index.byIdentifier[$0] })
        let forcedChain: Set<Int> = localCut.includeIntermediates
            ? Set(forcedIds.flatMap { chainToRoot($0, parentById: maps.parentById) })
            : forcedIds
        let labels = index.labelByGroupKey

        let bs = linesFor(.balance, roll: maps, totals: totalsBalance, labels: labels,
                          cut: localCut, forcedIds: forcedIds, forcedChain: forcedChain, omslag: omslag)
        let is_ = linesFor(.income,  roll: maps, totals: totalsIncome,  labels: labels,
                          cut: localCut, forcedIds: forcedIds, forcedChain: forcedChain, omslag: omslag)

        return StatementBundle(balance: bs, income: is_, totalsById: totalsBalance, entity: breakdown)
    }
}
