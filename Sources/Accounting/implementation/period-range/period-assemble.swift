import Foundation

public struct PeriodAssembleResultPeriod: Sendable {
    public let range: PeriodWindow
    public let bundle: StatementBundle
}

public struct PeriodAssembleResult: Sendable {
    // public let current: StatementBundle
    // public let previous: StatementBundle?

    public let current: PeriodAssembleResultPeriod
    public let previous: PeriodAssembleResultPeriod?
}

public enum PeriodAssembler {
    public static func assemble(
        shape: PeriodShape,
        anchor: Date,
        result: EntryCompileDriver.Result,
        cut: AssembleCut = .init(target: .L3, includeCodes: [], includeIntermediates: true, omitZerosBeyondLevel1: true),
        omslag: OmslagMode = .apply,
        entity: BusinessEntity = .vof,
        tz: TimeZone = .current,
        calendar: Calendar = {
            var c = Calendar(identifier: .iso8601); c.firstWeekday = 2; return c
        }()
    ) throws -> PeriodAssembleResult {

        // 0) Build the chart from nodes already in result.accounts
        let nodes = Array(result.accounts.byCode.values)
        let chart = try CompiledChart(name: "Project RGS",
                                      version: .init(major: 0, minor: 0),
                                      nodes: nodes) // ensures index + enriched parents
        // 1) Resolve all windows
        let wins = PeriodSlicer.resolve(shape: shape, anchor: anchor, tz: tz, calendar: calendar)

        // 2) Slice entries
        // let eHist = filterEntries(result.resolved, within: wins.historical)
        let eWin  = filterEntries(result.resolved, within: wins.window)
        let eYTD  = filterEntries(result.resolved, within: wins.ytd)

        // 3) Trial balances per slice
        // let tbHist = trialBalance(eHist)
        let tbWin  = trialBalance(eWin)
        let tbYTD  = trialBalance(eYTD)    // for BS as-of window end
        // (helper exists in your lib) :contentReference[oaicite:2]{index=2}

        // 4) Assemble using split seeds (unchanged) -> produce StatementBundle
        let currentBundle = try assembleSplitSeeds(
            chart: chart,
            tbIncomeWindow: tbWin,   // IS = window only
            tbBalanceYTD: tbYTD,     // BS = cumulative to window end
            tbOverlayForNI: tbYTD,    // overlay NI as-of window end (so BS balances)
            cut: cut,
            omslag: omslag,
            entity: entity
        )

        // wrap current with range
        let current = PeriodAssembleResultPeriod(range: wins.window, bundle: currentBundle)

        // 5) Optional previous-period comparison -> build previousPeriod if present
        var previous: PeriodAssembleResultPeriod? = nil
        if let p = wins.previous {
            let ePrevWin  = filterEntries(result.resolved, within: p)
            let ytdPrev   = PeriodWindow(from: nil, to: p.to)

            let tbPrevWin  = trialBalance(ePrevWin)
            let ePrevYTD   = filterEntries(result.resolved, within: ytdPrev)
            let tbPrevYTD  = trialBalance(ePrevYTD)

            let prevBundle = try assembleSplitSeeds(
                chart: chart,
                tbIncomeWindow: tbPrevWin,
                tbBalanceYTD: tbPrevYTD,
                tbOverlayForNI: tbPrevYTD, // overlay through prev.to
                cut: cut, omslag: omslag, entity: entity
            )

            previous = PeriodAssembleResultPeriod(range: p, bundle: prevBundle)
        }

        return .init(current: current, previous: previous)
    }

    // /// Core: do exactly what your RGSAssembler does, but with
    // /// (a) income totals from the *window* seed,
    // /// (b) balance totals from the *YTD* seed,
    // /// (c) NI overlay computed from the *historical* seed.
    // private static func assembleSplitSeeds(
    //     chart: CompiledChart,
    //     tbIncomeWindow: [TrialBalanceRow],
    //     tbBalanceYTD: [TrialBalanceRow],
    //     tbOverlayForNI: [TrialBalanceRow],
    //     cut: AssembleCut,
    //     omslag: OmslagMode,
    //     entity: BusinessEntity
    // ) throws -> StatementBundle {
    //     // maps + index
    //     let ch  = try chart.ensuringIndex(enrichNodes: true, strict: false)
    //     guard let index = ch.index else { throw RGSAssemblerError.missingIndex }

    //     let maps = try RGSAssembler.makeMaps(from: ch)
    //     RGSAssembler.assertEdgesMatchKeys(maps)

    //     // resolve auto-close targets (NI/equity) exactly like assembler does
    //     let targets  = AutoCloseTargets(for: entity)
    //     let resolved = try targets.resolve(in: index, validateWith: maps) // validates kinds .income/.balance :contentReference[oaicite:3]{index=3}

    //     // seeds
    //     let seedIncome = RGSAssembler.seedLeafs(from: tbIncomeWindow, using: index)
    //     let seedYTD    = RGSAssembler.seedLeafs(from: tbBalanceYTD, using: index)
    //     let seedHist   = RGSAssembler.seedLeafs(from: tbOverlayForNI, using: index)
    //     try RGSAssembler.assertSeedSumsToZero(seedIncome)
    //     try RGSAssembler.assertSeedSumsToZero(seedYTD)
    //     try RGSAssembler.assertSeedSumsToZero(seedHist)

    //     // compute NI from historical only (sum all income-kind nodes)
    //     let niHist = seedHist.reduce(into: Decimal(0)) { acc, kv in
    //         if maps.kindById[kv.key] == .income { acc += kv.value }
    //     }

    //     // apply overlay onto the YTD seed ONLY (don’t touch IS seed)
    //     var seedBalanceWithAC = seedYTD
    //     if niHist != 0 {
    //         seedBalanceWithAC[resolved.ni.id,     default: 0] += (-niHist)  // zero P&L
    //         seedBalanceWithAC[resolved.equity.id, default: 0] += ( niHist)  // push to equity
    //     }
    //     // rollups (deterministic SortingKey climb you use everywhere) :contentReference[oaicite:4]{index=4}
    //     var totalsIncome  = RGSAssembler.rollupBySortingKey(seedIncome,       idToKey: maps.sortKeyById, keyToId: maps.keyToId)
    //     let totalsBalance = RGSAssembler.rollupBySortingKey(seedBalanceWithAC, idToKey: maps.sortKeyById, keyToId: maps.keyToId)

    //     // put NI on the NI node for IS presentation (same behavior you have) :contentReference[oaicite:5]{index=5}
    //     let niWin = seedIncome.reduce(into: Decimal(0)) { acc, kv in
    //         if maps.kindById[kv.key] == .income { acc += kv.value }
    //     }
    //     if niWin != 0 {
    //         totalsIncome[resolved.ni.id, default: 0] += niWin
    //     }

    //     // forced inclusions & labels (identical to your assemble()) :contentReference[oaicite:6]{index=6}
    //     let forcedIds = Set(cut.includeCodes.compactMap { index.byIdentifier[$0] })
    //     let forcedChain: Set<Int> = cut.includeIntermediates
    //         ? Set(forcedIds.flatMap { chainToRoot($0, parentById: maps.parentById) })
    //         : forcedIds
    //     let labels = index.labelByGroupKey

    //     // build presentation lines (your public helper) :contentReference[oaicite:7]{index=7}
    //     let bs = linesFor(.balance, roll: maps, totals: totalsBalance,
    //                       labels: labels, cut: cut, forcedIds: forcedIds, forcedChain: forcedChain, omslag: omslag)
    //     let is_ = linesFor(.income,  roll: maps, totals: totalsIncome,
    //                        labels: labels, cut: cut, forcedIds: forcedIds, forcedChain: forcedChain, omslag: omslag)

    //     return StatementBundle(balance: bs, income: is_, totalsById: totalsBalance)
    // }

    /// Core: do exactly what your RGSAssembler does, but with
    /// (a) income totals from the *window* seed,
    /// (b) balance totals from the *YTD* seed,
    /// (c) NI overlay computed from the provided *overlay* seed (historical or YTD).
    private static func assembleSplitSeeds(
        chart: CompiledChart,
        tbIncomeWindow: [TrialBalanceRow],
        tbBalanceYTD: [TrialBalanceRow],
        tbOverlayForNI: [TrialBalanceRow],
        cut: AssembleCut,
        omslag: OmslagMode,
        entity: BusinessEntity
    ) throws -> StatementBundle {
        // maps + index
        let ch  = try chart.ensuringIndex(enrichNodes: true, strict: false)
        guard let index = ch.index else { throw RGSAssemblerError.missingIndex }

        let maps = try RGSAssembler.makeMaps(from: ch)
        RGSAssembler.assertEdgesMatchKeys(maps)

        // resolve auto-close targets (NI/equity) exactly like assembler does
        let targets  = AutoCloseTargets(for: entity)
        let resolved = try targets.resolve(in: index, validateWith: maps)

        // seeds
        let seedIncome  = RGSAssembler.seedLeafs(from: tbIncomeWindow,  using: index)
        let seedYTD     = RGSAssembler.seedLeafs(from: tbBalanceYTD,    using: index)
        let seedOverlay = RGSAssembler.seedLeafs(from: tbOverlayForNI,  using: index)
        try RGSAssembler.assertSeedSumsToZero(seedIncome)
        try RGSAssembler.assertSeedSumsToZero(seedYTD)
        try RGSAssembler.assertSeedSumsToZero(seedOverlay)

        // overlay NI from chosen overlay seed (historical or YTD depending on caller)
        let niOverlay = seedOverlay.reduce(into: Decimal(0)) { acc, kv in
            if maps.kindById[kv.key] == .income { acc += kv.value }
        }

        // respect manual postings on YTD seed (identical rule to RGSAssembler.assemble)
        let manualAtNi     = seedYTD[resolved.ni.id] ?? 0
        let manualAtEquity = seedYTD[resolved.equity.id] ?? 0
        let hasManual      = (manualAtNi != 0 || manualAtEquity != 0)

        // apply overlay onto the YTD seed ONLY (don’t touch IS seed)
        var seedBalanceWithAC = seedYTD
        if !hasManual && niOverlay != 0 {
            seedBalanceWithAC[resolved.ni.id,     default: 0] += (-niOverlay) // zero P&L
            seedBalanceWithAC[resolved.equity.id, default: 0] += ( niOverlay) // push to equity
        }

        // rollups (deterministic SortingKey climb)
        var totalsIncome  = RGSAssembler.rollupBySortingKey(
            seedIncome, idToKey: maps.sortKeyById, keyToId: maps.keyToId
        )
        let totalsBalance = RGSAssembler.rollupBySortingKey(
            seedBalanceWithAC, idToKey: maps.sortKeyById, keyToId: maps.keyToId
        )

        // place current-window NI on the NI node for IS presentation
        let niWindow = seedIncome.reduce(into: Decimal(0)) { acc, kv in
            if maps.kindById[kv.key] == .income { acc += kv.value }
        }
        if niWindow != 0 {
            totalsIncome[resolved.ni.id, default: 0] += niWindow
        }

        // force NI + Equity visible (even if zero), like RGSAssembler.assemble(autoClose: true)
        var localCut = cut
        localCut.includeCodes.append(contentsOf: [resolved.ni.code, resolved.equity.code])

        // forced inclusions & labels
        let forcedIds = Set(localCut.includeCodes.compactMap { index.byIdentifier[$0] })
        let forcedChain: Set<Int> = localCut.includeIntermediates
            ? Set(forcedIds.flatMap { chainToRoot($0, parentById: maps.parentById) })
            : forcedIds
        let labels = index.labelByGroupKey

        // build presentation lines
        let bs = linesFor(
            .balance, roll: maps, totals: totalsBalance, labels: labels,
            cut: localCut, forcedIds: forcedIds, forcedChain: forcedChain, omslag: omslag
        )
        let is_ = linesFor(
            .income, roll: maps, totals: totalsIncome, labels: labels,
            cut: localCut, forcedIds: forcedIds, forcedChain: forcedChain, omslag: omslag
        )

        return StatementBundle(balance: bs, income: is_, totalsById: totalsBalance)
    }
}
