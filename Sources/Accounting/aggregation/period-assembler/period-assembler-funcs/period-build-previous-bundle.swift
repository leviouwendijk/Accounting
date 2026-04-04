import Foundation

extension PeriodAssembler {
    @inline(__always)
    public static func buildPreviousBundle(
        chart: CompiledChart,
        wins: PeriodWindows,
        result: EntryCompileDriver.Result,
        cut: AssembleCut,
        omslag: OmslagMode,
        entity: BusinessEntity,
        shape: PeriodShape,
        calendar: Calendar
    ) throws -> (range: PeriodWindow, bundle: StatementBundle)? {
        guard let p = wins.previous else {
            return nil
        }

        let prevWin = p
        let ytdPrev = PeriodWindow(
            from: nil,
            to: p.to
        )
        let histPrev = PeriodWindow(
            from: nil,
            to: p.from.map { d in
                // Calendar.iso8601DayEnd(
                //     d.addingTimeInterval(-86400)
                // )
                let previousDay = calendar.date(
                    byAdding: .day,
                    value: -1,
                    to: d
                )!

                return calendar.dayEnd(previousDay)
            }
        )

        var ePrevWin: [ResolvedEntry] = []
        var ePrevHist: [ResolvedEntry] = []
        var ePrevYTD: [ResolvedEntry] = []

        ePrevWin.reserveCapacity(result.resolved.count)
        ePrevHist.reserveCapacity(result.resolved.count)
        ePrevYTD.reserveCapacity(result.resolved.count)

        for re in result.resolved {
            guard let d = absDate(re.date) else {
                continue
            }

            if within(d, window: prevWin) {
                ePrevWin.append(re)
            }

            if within(d, window: histPrev) {
                ePrevHist.append(re)
            }

            if within(d, window: ytdPrev) {
                ePrevYTD.append(re)
            }
        }

        let idIndex = result.entities.idIndex

        let tbPrevWin = trialBalance(
            ePrevWin,
            entityId: { idIndex[$0] }
        )
        let tbPrevYTD = trialBalance(
            ePrevYTD,
            entityId: { idIndex[$0] }
        )
        let tbPrevHist = trialBalance(
            ePrevHist,
            entityId: { idIndex[$0] }
        )

        let bsBase = shape.rangeToDate
            ? tbPrevYTD
            : tbPrevWin

        let niSource = shape.rangeToDate
            ? tbPrevYTD
            : tbPrevWin

        let slicesPrev = result.entities.ownershipSlices(
            asOf: p.to ?? Date()
        )

        let bundle = try assembleSplitSeeds(
            chart: chart,
            tbIncomeWindow: tbPrevWin,
            tbBalanceWindow: bsBase,
            tbOverlayForNI: niSource,
            tbPreWindowForOpening: tbPrevHist,
            cut: cut,
            omslag: omslag,
            entity: entity,
            ownershipSlices: slicesPrev,
            entityIdOnRow: { $0.entityId }
        )

        return (
            p,
            attachFinancialAverages(
                bundle,
                shape: shape,
                range: p,
                calendar: calendar
            )
        )
    }
}

extension PeriodAssembler {
    public static func buildPreviousBundleConcurrent(
        chart: CompiledChart,
        wins: PeriodWindows,
        result: EntryCompileDriver.Result,
        cut: AssembleCut,
        omslag: OmslagMode,
        entity: BusinessEntity,
        shape: PeriodShape,
        calendar: Calendar
    ) async throws -> (range: PeriodWindow, bundle: StatementBundle)? {
        guard let p = wins.previous else {
            return nil
        }

        let prevWin = p
        let ytdPrev = PeriodWindow(
            from: nil,
            to: p.to
        )
        let histPrev = PeriodWindow(
            from: nil,
            to: p.from.map { d in
                // Calendar.iso8601DayEnd(
                //     d.addingTimeInterval(-86400)
                // )
                let previousDay = calendar.date(
                    byAdding: .day,
                    value: -1,
                    to: d
                )!

                return calendar.dayEnd(previousDay)
            }
        )

        var ePrevWin: [ResolvedEntry] = []
        var ePrevHist: [ResolvedEntry] = []
        var ePrevYTD: [ResolvedEntry] = []

        ePrevWin.reserveCapacity(result.resolved.count)
        ePrevHist.reserveCapacity(result.resolved.count)
        ePrevYTD.reserveCapacity(result.resolved.count)

        for re in result.resolved {
            guard let d = absDate(re.date) else {
                continue
            }

            if within(d, window: prevWin) {
                ePrevWin.append(re)
            }

            if within(d, window: histPrev) {
                ePrevHist.append(re)
            }

            if within(d, window: ytdPrev) {
                ePrevYTD.append(re)
            }
        }

        let idIndex = result.entities.idIndex

        async let tbPrevWinTask: [TrialBalanceRow] = trialBalance(
            ePrevWin,
            entityId: { idIndex[$0] }
        )
        async let tbPrevYTDTask: [TrialBalanceRow] = trialBalance(
            ePrevYTD,
            entityId: { idIndex[$0] }
        )
        async let tbPrevHistTask: [TrialBalanceRow] = trialBalance(
            ePrevHist,
            entityId: { idIndex[$0] }
        )

        let tbPrevWin = await tbPrevWinTask
        let tbPrevYTD = await tbPrevYTDTask
        let tbPrevHist = await tbPrevHistTask

        let bsBase = shape.rangeToDate
            ? tbPrevYTD
            : tbPrevWin

        let niSource = shape.rangeToDate
            ? tbPrevYTD
            : tbPrevWin

        let slicesPrev = result.entities.ownershipSlices(
            asOf: p.to ?? Date()
        )

        let bundle = try assembleSplitSeeds(
            chart: chart,
            tbIncomeWindow: tbPrevWin,
            tbBalanceWindow: bsBase,
            tbOverlayForNI: niSource,
            tbPreWindowForOpening: tbPrevHist,
            cut: cut,
            omslag: omslag,
            entity: entity,
            ownershipSlices: slicesPrev,
            entityIdOnRow: { $0.entityId }
        )

        return (
            p,
            attachFinancialAverages(
                bundle,
                shape: shape,
                range: p,
                calendar: calendar
            )
        )
    }
}
