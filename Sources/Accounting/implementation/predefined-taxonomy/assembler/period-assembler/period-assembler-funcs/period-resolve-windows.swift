import Foundation

public extension PeriodAssembler {
    @inline(__always)
    static func resolveWindows(
        shape: PeriodShape,
        anchor: Date,
        tz: TimeZone,
        calendar: Calendar
    ) -> PeriodWindows {
        PeriodSlicer.resolve(shape: shape, anchor: anchor, tz: tz, calendar: calendar)
    }

    @inline(__always)
    static func entriesForWindows(
        _ all: [ResolvedEntry],
        wins: PeriodWindows
    ) -> (hist: [ResolvedEntry], win: [ResolvedEntry], ytd: [ResolvedEntry]) {
        let eHist = filterEntries(all, within: wins.historical)
        let eWin  = filterEntries(all, within: wins.window)
        let eYTD  = filterEntries(all, within: wins.ytd)
        return (eHist, eWin, eYTD)
    }

    @inline(__always)
    static func trialBalances(
        hist: [ResolvedEntry], win: [ResolvedEntry], ytd: [ResolvedEntry]
    ) -> (tbHist: [TrialBalanceRow], tbWin: [TrialBalanceRow], tbYTD: [TrialBalanceRow]) {
        (trialBalance(hist), trialBalance(win), trialBalance(ytd))
    }
}
