// ROLLBACK ON REGRESSION:
// import Foundation

// public extension PeriodAssembler {
//     @inline(__always)
//     static func buildCurrentBundle(
//         chart: CompiledChart,
//         wins: PeriodWindows,
//         result: EntryCompileDriver.Result,
//         cut: AssembleCut,
//         omslag: OmslagMode,
//         entity: BusinessEntity,
//         // rangeToDate: Bool
//         shape: PeriodShape,
//         calendar: Calendar
//     ) throws -> StatementBundle {
//         let (eHist, eWin, eYTD) = entriesForWindows(
//             result.resolved,
//             wins
//         )

//         let idIndex = result.entities.idIndex

//         let tbHist = trialBalance(
//             eHist,
//             entityId: { idIndex[$0] }
//         )
//         let tbWin = trialBalance(
//             eWin,
//             entityId: { idIndex[$0] }
//         )
//         let tbYTD = trialBalance(
//             eYTD,
//             entityId: { idIndex[$0] }
//         )

//         let bsBase = shape.rangeToDate
//             ? tbYTD
//             : tbWin

//         let niSource = shape.rangeToDate
//             ? tbYTD
//             : tbWin

//         let slices = result.entities.ownershipSlices(
//             asOf: wins.window.to ?? Date()
//         )

//         let bundle = try assembleSplitSeeds(
//             chart: chart,
//             tbIncomeWindow: tbWin,
//             tbBalanceWindow: bsBase,
//             tbOverlayForNI: niSource,
//             tbPreWindowForOpening: tbHist,
//             cut: cut,
//             omslag: omslag,
//             entity: entity,
//             ownershipSlices: slices,
//             entityIdOnRow: { $0.entityId }
//         )

//         return attachFinancialAverages(
//             bundle,
//             shape: shape,
//             range: wins.window,
//             calendar: calendar
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
//         rangeToDate: Bool
//     ) throws -> (range: PeriodWindow, bundle: StatementBundle)? {

//         guard let p = wins.previous else { return nil }

//         // Previous window entries
//         let ePrevWin = filterEntries(result.resolved, within: p)
//         let ytdPrev  = PeriodWindow(from: nil, to: p.to)
//         let histPrev = PeriodWindow(from: nil, to: p.from.map { d in
//             var cal = Calendar(identifier: .iso8601); cal.firstWeekday = 2
//             var comps = cal.dateComponents([.year,.month,.day], from: d.addingTimeInterval(-86400))
//             comps.hour = 23; comps.minute = 59; comps.second = 59
//             return cal.date(from: comps)!
//         })

//         let ePrevHist = filterEntries(result.resolved, within: histPrev)
//         let ePrevYTD  = filterEntries(result.resolved, within: ytdPrev)

//         // Map entities -> stable ids
//         let idIndex = result.entities.idIndex

//         // TBs with entity preserved
//         let tbPrevWin  = trialBalance(ePrevWin,  entityId: { idIndex[$0] })
//         let tbPrevYTD  = trialBalance(ePrevYTD,  entityId: { idIndex[$0] })
//         let tbPrevHist = trialBalance(ePrevHist, entityId: { idIndex[$0] })

//         // Choose window vs YTD
//         let bsBase   = rangeToDate ? tbPrevYTD : tbPrevWin
//         let niSource = rangeToDate ? tbPrevYTD : tbPrevWin

//         // Slices as of previous period end
//         let slicesPrev = result.entities.ownershipSlices(asOf: p.to ?? Date())

//         let prevBundle = try assembleSplitSeeds(
//             chart: chart,
//             tbIncomeWindow: tbPrevWin,
//             tbBalanceWindow: bsBase,
//             tbOverlayForNI: niSource,
//             tbPreWindowForOpening: tbPrevHist,
//             cut: cut, omslag: omslag, entity: entity,
//             ownershipSlices: slicesPrev,
//             entityIdOnRow: { $0.entityId }
//         )

//         return (p, prevBundle)
//     }
// }

// extension PeriodAssembler {
//     /// Async variant: same semantics, but computes TBs in parallel.
//     public static func buildCurrentBundleConcurrent(
//         chart: CompiledChart,
//         wins: PeriodWindows,
//         result: EntryCompileDriver.Result,
//         cut: AssembleCut,
//         omslag: OmslagMode,
//         entity: BusinessEntity,
//         rangeToDate: Bool
//     ) async throws -> StatementBundle {

//         let (eHist, eWin, eYTD) = entriesForWindows(result.resolved, wins)
//         let idIndex = result.entities.idIndex

//         async let tbHistTask: [TrialBalanceRow] = trialBalance(eHist, entityId: { idIndex[$0] })
//         async let tbWinTask:  [TrialBalanceRow] = trialBalance(eWin,  entityId: { idIndex[$0] })
//         async let tbYTDTask:  [TrialBalanceRow] = trialBalance(eYTD,  entityId: { idIndex[$0] })

//         let tbHist = await tbHistTask
//         let tbWin  = await tbWinTask
//         let tbYTD  = await tbYTDTask

//         let bsBase   = rangeToDate ? tbYTD : tbWin
//         let niSource = rangeToDate ? tbYTD : tbWin
//         let slices   = result.entities.ownershipSlices(asOf: wins.window.to ?? Date())

//         return try assembleSplitSeeds(
//             chart: chart,
//             tbIncomeWindow: tbWin,
//             tbBalanceWindow: bsBase,
//             tbOverlayForNI: niSource,
//             tbPreWindowForOpening: tbHist,
//             cut: cut, omslag: omslag, entity: entity,
//             ownershipSlices: slices,
//             entityIdOnRow: { $0.entityId }
//         )
//     }

//     public static func buildPreviousBundleConcurrent(
//         chart: CompiledChart,
//         wins: PeriodWindows,
//         result: EntryCompileDriver.Result,
//         cut: AssembleCut,
//         omslag: OmslagMode,
//         entity: BusinessEntity,
//         rangeToDate: Bool
//     ) async throws -> (range: PeriodWindow, bundle: StatementBundle)? {
//         guard let p = wins.previous else { return nil }

//         // Windows for previous period
//         let prevWin  = p
//         let ytdPrev  = PeriodWindow(from: nil, to: p.to)
//         let histPrev = PeriodWindow(
//             from: nil,
//             to: p.from.map { d in
//                 Calendar.iso8601DayEnd(d.addingTimeInterval(-86400))
//             }
//         )

//         // Single pass over resolved entries for all three windows
//         var ePrevWin:  [ResolvedEntry] = []
//         var ePrevHist: [ResolvedEntry] = []
//         var ePrevYTD:  [ResolvedEntry] = []

//         ePrevWin.reserveCapacity(result.resolved.count)
//         ePrevHist.reserveCapacity(result.resolved.count)
//         ePrevYTD.reserveCapacity(result.resolved.count)

//         for re in result.resolved {
//             guard let d = absDate(re.date) else { continue }

//             if within(d, window: prevWin)   { ePrevWin.append(re) }
//             if within(d, window: histPrev)  { ePrevHist.append(re) }
//             if within(d, window: ytdPrev)   { ePrevYTD.append(re) }
//         }

//         // Map entities -> stable ids
//         let idIndex = result.entities.idIndex

//         // TBs with entity preserved – run in parallel
//         async let tbPrevWinTask:  [TrialBalanceRow] = trialBalance(ePrevWin,  entityId: { idIndex[$0] })
//         async let tbPrevYTDTask:  [TrialBalanceRow] = trialBalance(ePrevYTD,  entityId: { idIndex[$0] })
//         async let tbPrevHistTask: [TrialBalanceRow] = trialBalance(ePrevHist, entityId: { idIndex[$0] })

//         let tbPrevWin  = await tbPrevWinTask
//         let tbPrevYTD  = await tbPrevYTDTask
//         let tbPrevHist = await tbPrevHistTask

//         // Choose window vs YTD
//         let bsBase   = rangeToDate ? tbPrevYTD : tbPrevWin
//         let niSource = rangeToDate ? tbPrevYTD : tbPrevWin

//         // Slices as of previous period end
//         let slicesPrev = result.entities.ownershipSlices(asOf: p.to ?? Date())

//         let prevBundle = try assembleSplitSeeds(
//             chart: chart,
//             tbIncomeWindow: tbPrevWin,
//             tbBalanceWindow: bsBase,
//             tbOverlayForNI: niSource,
//             tbPreWindowForOpening: tbPrevHist,
//             cut: cut, omslag: omslag, entity: entity,
//             ownershipSlices: slicesPrev,
//             entityIdOnRow: { $0.entityId }
//         )

//         return (p, prevBundle)
//     }
// }
