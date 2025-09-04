import Foundation

public extension PeriodAssembler {
    /// Core: IS from window; BS = OpeningBeg(from pre-window) + YTD(with AC overlay); NI overlay from YTD (suppressed if manual).
    @inline(__always)
    static func assembleSplitSeeds(
        chart: CompiledChart,
        tbIncomeWindow: [TrialBalanceRow],
        // tbBalanceYTD: [TrialBalanceRow],
        tbBalanceWindow: [TrialBalanceRow],
        tbOverlayForNI: [TrialBalanceRow],
        tbPreWindowForOpening: [TrialBalanceRow]?,   // ← NEW: pre-window seed for *Beg mapping
        cut: AssembleCut,
        omslag: OmslagMode,
        entity: BusinessEntity
    ) throws -> StatementBundle {

        // maps + index
        let ch  = try chart.ensuringIndex(enrichNodes: true, strict: false)
        guard let index = ch.index else { throw RGSAssemblerError.missingIndex }

        let maps = try RGSAssembler.makeMaps(from: ch)

        // resolve NI/Equity (with kind validation)
        let targets  = AutoCloseTargets(for: entity)
        let resolved = try targets.resolve(in: index, validateWith: maps)

        let routing = entity.periodOpeningRouting

        // seeds
        let seedIncome  = RGSAssembler.seedLeafs(from: tbIncomeWindow,  using: index)
        // let seedYTD     = RGSAssembler.seedLeafs(from: tbBalanceYTD,    using: index)
        let seedWinBal  = RGSAssembler.seedLeafs(from: tbBalanceWindow, using: index)
        let seedOverlay = RGSAssembler.seedLeafs(from: tbOverlayForNI,  using: index)
        try RGSAssembler.assertSeedSumsToZero(seedIncome)
        // try RGSAssembler.assertSeedSumsToZero(seedYTD)
        try RGSAssembler.assertSeedSumsToZero(seedWinBal)
        try RGSAssembler.assertSeedSumsToZero(seedOverlay)

        // OpeningBeg from pre-window → map to "<L4>Beg" when present (balance accounts only)
        let seedOpening: [Int: Decimal] = {
            guard let tbHist = tbPreWindowForOpening, !tbHist.isEmpty else { return [:] }
            // return RGSAssembler.openingBegSeed(from: tbHist, chart: ch, index: index, maps: maps)
            return RGSAssembler.openingBegSeed(
                from: tbHist,
                chart: ch,
                index: index,
                maps: maps,
                routing: routing
            )
        }()

        // Base BS seed = OpeningBeg + YTD
        var seedBalance = seedOpening
        // for (k, v) in seedYTD { seedBalance[k, default: 0] += v }
        for (k, v) in seedWinBal { seedBalance[k, default: 0] += v }


        // NI overlay from overlay seed (normally YTD), unless manual postings exist
        let niOverlay = seedOverlay.reduce(into: Decimal(0)) { acc, kv in
            if maps.kindById[kv.key] == .income { acc += kv.value }
        }

        // let hasManual = (seedBalance[resolved.ni.id] ?? 0) != 0 || (seedBalance[resolved.equity.id] ?? 0) != 0
        let hasManual = false

        if !hasManual && niOverlay != 0 {
            seedBalance[resolved.ni.id,     default: 0] += (-niOverlay)
            seedBalance[resolved.equity.id, default: 0] += ( niOverlay)
        }

        var totalsIncome  = RGSAssembler.rollupAmounts(seedIncome,  parentById: maps.parentById)
        let totalsBalance = RGSAssembler.rollupAmounts(seedBalance, parentById: maps.parentById)

        let niWindow = seedIncome.reduce(into: Decimal(0)) { acc, kv in
            if maps.kindById[kv.key] == .income { acc += kv.value }
        }
        if niWindow != 0 { totalsIncome[resolved.ni.id, default: 0] += niWindow }

        // Force NI + Equity visible (like RGSAssembler.assemble(autoClose: true))
        var localCut = cut
        localCut.includeCodes.append(contentsOf: [resolved.ni.code, resolved.equity.code])

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

        return StatementBundle(balance: bs, income: is_, totalsById: totalsBalance)
    }
}
