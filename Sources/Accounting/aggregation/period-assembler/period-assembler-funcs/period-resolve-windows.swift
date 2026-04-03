import Foundation

public extension PeriodAssembler {
    @inline(__always)
    static func resolveWindows(
        shape: PeriodShape,
        anchor: Date,
        calendar: Calendar
    ) -> PeriodWindows {
        PeriodSlicer.resolve(
            shape: shape,
            anchor: anchor,
            calendar: calendar
        )
    }

    @inline(__always)
    static func entriesForWindows(
        _ src: [ResolvedEntry],
        _ w: PeriodWindows
    ) -> (
        historical: [ResolvedEntry],
        window: [ResolvedEntry],
        ytd: [ResolvedEntry]
    ) {
        var historical: [ResolvedEntry] = []
        var windowSlice: [ResolvedEntry] = []
        var ytd: [ResolvedEntry] = []

        historical.reserveCapacity(src.count)
        windowSlice.reserveCapacity(src.count)
        ytd.reserveCapacity(src.count)

        for re in src {
            guard let d = absDate(re.date) else {
                continue
            }

            if within(d, window: w.historical) {
                historical.append(re)
            }

            if within(d, window: w.window) {
                windowSlice.append(re)
            }

            if within(d, window: w.ytd) {
                ytd.append(re)
            }
        }

        return (historical, windowSlice, ytd)
    }

    @inline(__always)
    static func trialBalances(
        hist: [ResolvedEntry],
        win: [ResolvedEntry],
        ytd: [ResolvedEntry]
    ) -> (tbHist: [TrialBalanceRow], tbWin: [TrialBalanceRow], tbYTD: [TrialBalanceRow]) {
        (
            trialBalance(hist),
            trialBalance(win),
            trialBalance(ytd)
        )
    }
}

// public extension PeriodAssembler {
//     @inline(__always)
//     static func resolveWindows(
//         shape: PeriodShape,
//         anchor: Date,
//         tz: TimeZone,
//         calendar: Calendar
//     ) -> PeriodWindows {
//         PeriodSlicer.resolve(shape: shape, anchor: anchor, tz: tz, calendar: calendar)
//     }

//     // @inline(__always)
//     // static func entriesForWindows(
//     //     _ all: [ResolvedEntry],
//     //     wins: PeriodWindows
//     // ) -> (hist: [ResolvedEntry], win: [ResolvedEntry], ytd: [ResolvedEntry]) {
//     //     let eHist = filterEntries(all, within: wins.historical)
//     //     let eWin  = filterEntries(all, within: wins.window)
//     //     let eYTD  = filterEntries(all, within: wins.ytd)
//     //     return (eHist, eWin, eYTD)
//     // }

//     @inline(__always)
//     static func entriesForWindows(
//         _ src: [ResolvedEntry],
//         _ w: PeriodWindows
//     ) -> (historical: [ResolvedEntry], window: [ResolvedEntry], ytd: [ResolvedEntry]) {
//         var historical: [ResolvedEntry] = []
//         var windowSlice: [ResolvedEntry] = []
//         var ytd: [ResolvedEntry] = []

//         historical.reserveCapacity(src.count)
//         windowSlice.reserveCapacity(src.count)
//         ytd.reserveCapacity(src.count)

//         for re in src {
//             guard let d = absDate(re.date) else { continue }

//             if within(d, window: w.historical) {
//                 historical.append(re)
//             }
//             if within(d, window: w.window) {
//                 windowSlice.append(re)
//             }
//             if within(d, window: w.ytd) {
//                 ytd.append(re)
//             }
//         }

//         return (historical, windowSlice, ytd)
//     }

//     @inline(__always)
//     static func trialBalances(
//         hist: [ResolvedEntry], win: [ResolvedEntry], ytd: [ResolvedEntry]
//     ) -> (tbHist: [TrialBalanceRow], tbWin: [TrialBalanceRow], tbYTD: [TrialBalanceRow]) {
//         (trialBalance(hist), trialBalance(win), trialBalance(ytd))
//     }
// }
