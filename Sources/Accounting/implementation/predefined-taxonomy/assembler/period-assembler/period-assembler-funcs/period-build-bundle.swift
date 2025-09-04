import Foundation

public extension PeriodAssembler {
    @inline(__always)
    static func buildCurrentBundle(
        chart: CompiledChart,
        wins: PeriodWindows,
        result: EntryCompileDriver.Result,
        cut: AssembleCut,
        omslag: OmslagMode,
        entity: BusinessEntity
    ) throws -> StatementBundle {

        let (eHist, eWin, eYTD) = entriesForWindows(result.resolved, wins: wins)
        let (tbHist, tbWin, tbYTD) = trialBalances(hist: eHist, win: eWin, ytd: eYTD)

        // IS = tbWin, BS = OpeningBeg(tbHist) + tbYTD, NI overlay = tbYTD
        return try assembleSplitSeeds(
            chart: chart,
            tbIncomeWindow: tbWin,
            tbBalanceYTD: tbYTD,
            tbOverlayForNI: tbYTD,
            tbPreWindowForOpening: tbHist,
            cut: cut, omslag: omslag, entity: entity
        )
    }

    @inline(__always)
    static func buildPreviousBundle(
        chart: CompiledChart,
        wins: PeriodWindows,
        result: EntryCompileDriver.Result,
        cut: AssembleCut,
        omslag: OmslagMode,
        entity: BusinessEntity
    ) throws -> (range: PeriodWindow, bundle: StatementBundle)? {

        guard let p = wins.previous else { return nil }

        // Slice prev window + its YTD (through p.to) and hist (pre p.from)
        let ePrevWin = filterEntries(result.resolved, within: p)
        let ytdPrev  = PeriodWindow(from: nil, to: p.to)
        let histPrev = PeriodWindow(from: nil, to: p.from.map { d in
            var cal = Calendar(identifier: .iso8601); cal.firstWeekday = 2
            let dayEnd = { (x: Date) -> Date in
                var c = cal.dateComponents([.year,.month,.day], from: x)
                c.hour = 23; c.minute = 59; c.second = 59
                return cal.date(from: c)!
            }
            return dayEnd(cal.date(byAdding: .day, value: -1, to: d)!)
        })

        let ePrevHist = filterEntries(result.resolved, within: histPrev)
        let ePrevYTD  = filterEntries(result.resolved, within: ytdPrev)

        let tbPrevWin  = trialBalance(ePrevWin)
        let tbPrevYTD  = trialBalance(ePrevYTD)
        let tbPrevHist = trialBalance(ePrevHist)

        let prevBundle = try assembleSplitSeeds(
            chart: chart,
            tbIncomeWindow: tbPrevWin,
            tbBalanceYTD: tbPrevYTD,
            tbOverlayForNI: tbPrevYTD,
            tbPreWindowForOpening: tbPrevHist,
            cut: cut, omslag: omslag, entity: entity
        )

        return (p, prevBundle)
    }
}
