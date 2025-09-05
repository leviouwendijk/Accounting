import Foundation

public extension PeriodAssembler {
    @inline(__always)
    static func buildCurrentBundle(
        chart: CompiledChart,
        wins: PeriodWindows,
        result: EntryCompileDriver.Result,
        cut: AssembleCut,
        omslag: OmslagMode,
        entity: BusinessEntity,
        rangeToDate: Bool
    ) throws -> StatementBundle {

        // Slice entries
        let (eHist, eWin, eYTD) = entriesForWindows(result.resolved, wins: wins)

        // Map entities -> stable ids
        let idIndex = result.entities.idIndex

        // Trial balances that **preserve entity**
        let tbHist = trialBalance(eHist, entityId: { idIndex[$0] })
        let tbWin  = trialBalance(eWin,  entityId: { idIndex[$0] })
        let tbYTD  = trialBalance(eYTD,  entityId: { idIndex[$0] })

        // Choose window vs YTD
        let bsBase   = rangeToDate ? tbYTD : tbWin
        let niSource = rangeToDate ? tbYTD : tbWin

        // Ownership slices as of period end
        let slices = result.entities.ownershipSlices(asOf: wins.window.to ?? Date())

        return try assembleSplitSeeds(
            chart: chart,
            tbIncomeWindow: tbWin,          // IS = window
            tbBalanceWindow: bsBase,        // BS movements = window (or YTD if rangeToDate)
            tbOverlayForNI: niSource,       // overlay = same source you present
            tbPreWindowForOpening: tbHist,  // openings = pre-window
            cut: cut, omslag: omslag, entity: entity,
            ownershipSlices: slices,
            entityIdOnRow: { $0.entityId }  // ← IMPORTANT: plumbs entity into AE path
        )
    }

    @inline(__always)
    static func buildPreviousBundle(
        chart: CompiledChart,
        wins: PeriodWindows,
        result: EntryCompileDriver.Result,
        cut: AssembleCut,
        omslag: OmslagMode,
        entity: BusinessEntity,
        rangeToDate: Bool
    ) throws -> (range: PeriodWindow, bundle: StatementBundle)? {

        guard let p = wins.previous else { return nil }

        // Previous window entries
        let ePrevWin = filterEntries(result.resolved, within: p)
        let ytdPrev  = PeriodWindow(from: nil, to: p.to)
        let histPrev = PeriodWindow(from: nil, to: p.from.map { d in
            var cal = Calendar(identifier: .iso8601); cal.firstWeekday = 2
            var comps = cal.dateComponents([.year,.month,.day], from: d.addingTimeInterval(-86400))
            comps.hour = 23; comps.minute = 59; comps.second = 59
            return cal.date(from: comps)!
        })

        let ePrevHist = filterEntries(result.resolved, within: histPrev)
        let ePrevYTD  = filterEntries(result.resolved, within: ytdPrev)

        // Map entities -> stable ids
        let idIndex = result.entities.idIndex

        // TBs with entity preserved
        let tbPrevWin  = trialBalance(ePrevWin,  entityId: { idIndex[$0] })
        let tbPrevYTD  = trialBalance(ePrevYTD,  entityId: { idIndex[$0] })
        let tbPrevHist = trialBalance(ePrevHist, entityId: { idIndex[$0] })

        // Choose window vs YTD
        let bsBase   = rangeToDate ? tbPrevYTD : tbPrevWin
        let niSource = rangeToDate ? tbPrevYTD : tbPrevWin

        // Slices as of previous period end
        let slicesPrev = result.entities.ownershipSlices(asOf: p.to ?? Date())

        let prevBundle = try assembleSplitSeeds(
            chart: chart,
            tbIncomeWindow: tbPrevWin,
            tbBalanceWindow: bsBase,
            tbOverlayForNI: niSource,
            tbPreWindowForOpening: tbPrevHist,
            cut: cut, omslag: omslag, entity: entity,
            ownershipSlices: slicesPrev,
            entityIdOnRow: { $0.entityId }
        )

        return (p, prevBundle)
    }
}

public extension Calendar {
    static var iso8601: Calendar { var c = Calendar(identifier: .iso8601); c.firstWeekday = 2; return c }
    static func iso8601DayEnd(_ d: Date) -> Date {
        var c = Calendar.iso8601.dateComponents([.year,.month,.day], from: d)
        c.hour = 23; c.minute = 59; c.second = 59
        return Calendar.iso8601.date(from: c)!
    }
}


// public extension PeriodAssembler {
//     @inline(__always)
//     static func buildCurrentBundle(
//         chart: CompiledChart,
//         wins: PeriodWindows,
//         result: EntryCompileDriver.Result,
//         cut: AssembleCut,
//         omslag: OmslagMode,
//         entity: BusinessEntity,
//         rangeToDate: Bool                  // ← NEW
//     ) throws -> StatementBundle {

//         let (eHist, eWin, eYTD) = entriesForWindows(result.resolved, wins: wins)
//         let (tbHist, tbWin, tbYTD) = trialBalances(hist: eHist, win: eWin, ytd: eYTD)

//         // IS always = window
//         // BS movements + NI overlay = window, unless range-to-date requested
//         let bsBase   = rangeToDate ? tbYTD : tbWin
//         let niSource = rangeToDate ? tbYTD : tbWin

//         return try assembleSplitSeeds(
//             chart: chart,
//             tbIncomeWindow: tbWin,
//             tbBalanceWindow: bsBase,        // ← was tbBalanceYTD
//             tbOverlayForNI: niSource,       // ← was tbYTD
//             tbPreWindowForOpening: tbHist,
//             cut: cut, omslag: omslag, entity: entity
//         )
//     }

//     @inline(__always)
//     static func buildPreviousBundle(
//         chart: CompiledChart,
//         wins: PeriodWindows,
//         result: EntryCompileDriver.Result,
//         cut: AssembleCut,
//         omslag: OmslagMode,
//         entity: BusinessEntity,
//         rangeToDate: Bool                  // ← NEW
//     ) throws -> (range: PeriodWindow, bundle: StatementBundle)? {

//         guard let p = wins.previous else { return nil }

//         // Slice prev window + its YTD (through p.to) and hist (pre p.from)
//         let ePrevWin = filterEntries(result.resolved, within: p)
//         let ytdPrev  = PeriodWindow(from: nil, to: p.to)
//         let histPrev = PeriodWindow(from: nil, to: p.from.map { d in
//             var cal = Calendar(identifier: .iso8601); cal.firstWeekday = 2
//             let dayEnd = { (x: Date) -> Date in
//                 var c = cal.dateComponents([.year,.month,.day], from: x)
//                 c.hour = 23; c.minute = 59; c.second = 59
//                 return cal.date(from: c)!
//             }
//             return dayEnd(cal.date(byAdding: .day, value: -1, to: d)!)
//         })

//         let ePrevHist = filterEntries(result.resolved, within: histPrev)
//         let ePrevYTD  = filterEntries(result.resolved, within: ytdPrev)

//         let tbPrevWin  = trialBalance(ePrevWin)
//         let tbPrevYTD  = trialBalance(ePrevYTD)
//         let tbPrevHist = trialBalance(ePrevHist)

//         let bsBase   = rangeToDate ? tbPrevYTD : tbPrevWin
//         let niSource = rangeToDate ? tbPrevYTD : tbPrevWin

//         let prevBundle = try assembleSplitSeeds(
//             chart: chart,
//             tbIncomeWindow: tbPrevWin,
//             tbBalanceWindow: bsBase,        // ← was tbBalanceYTD
//             tbOverlayForNI: niSource,       // ← was tbPrevYTD
//             tbPreWindowForOpening: tbPrevHist,
//             cut: cut, omslag: omslag, entity: entity
//         )

//         return (p, prevBundle)
//     }
// }
