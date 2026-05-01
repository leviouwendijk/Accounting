import Accounting
import Foundation

extension PeriodAssembler {
    @inline(__always)
    public static func buildCurrentBundle(
        chart: CompiledChart,
        wins: PeriodWindows,
        result: EntryCompileDriver.Result,
        cut: AssembleCut,
        omslag: OmslagMode,
        entity: BusinessEntity,
        shape: PeriodShape,
        calendar: Calendar
    ) throws -> StatementBundle {
        let (eHist, eWin, eYTD) = entriesForWindows(
            result.resolved,
            wins
        )

        let idIndex = result.entities.idIndex

        let tbHist = trialBalance(
            eHist,
            entityId: { idIndex[$0] }
        )
        let tbWin = trialBalance(
            eWin,
            entityId: { idIndex[$0] }
        )
        let tbYTD = trialBalance(
            eYTD,
            entityId: { idIndex[$0] }
        )

        let bsBase = shape.rangeToDate
            ? tbYTD
            : tbWin

        let niSource = shape.rangeToDate
            ? tbYTD
            : tbWin

        let slices = result.entities.ownershipSlices(
            asOf: wins.window.to ?? Date()
        )

        let bundle = try assembleSplitSeeds(
            chart: chart,
            tbIncomeWindow: tbWin,
            tbBalanceWindow: bsBase,
            tbOverlayForNI: niSource,
            tbPreWindowForOpening: tbHist,
            cut: cut,
            omslag: omslag,
            entity: entity,
            ownershipSlices: slices,
            entityIdOnRow: { $0.entityId }
        )

        return attachFinancialAverages(
            bundle,
            shape: shape,
            range: wins.window,
            calendar: calendar
        )
    }
}

extension PeriodAssembler {
    public static func buildCurrentBundleConcurrent(
        chart: CompiledChart,
        wins: PeriodWindows,
        result: EntryCompileDriver.Result,
        cut: AssembleCut,
        omslag: OmslagMode,
        entity: BusinessEntity,
        shape: PeriodShape,
        calendar: Calendar
    ) async throws -> StatementBundle {
        let (eHist, eWin, eYTD) = entriesForWindows(
            result.resolved,
            wins
        )

        let idIndex = result.entities.idIndex

        async let tbWinTask: [TrialBalanceRow] = trialBalance(
            eWin,
            entityId: { idIndex[$0] }
        )
        async let tbYTDTask: [TrialBalanceRow] = trialBalance(
            eYTD,
            entityId: { idIndex[$0] }
        )
        async let tbHistTask: [TrialBalanceRow] = trialBalance(
            eHist,
            entityId: { idIndex[$0] }
        )

        let tbWin = await tbWinTask
        let tbYTD = await tbYTDTask
        let tbHist = await tbHistTask

        let bsBase = shape.rangeToDate
            ? tbYTD
            : tbWin

        let niSource = shape.rangeToDate
            ? tbYTD
            : tbWin

        let slices = result.entities.ownershipSlices(
            asOf: wins.window.to ?? Date()
        )

        let bundle = try assembleSplitSeeds(
            chart: chart,
            tbIncomeWindow: tbWin,
            tbBalanceWindow: bsBase,
            tbOverlayForNI: niSource,
            tbPreWindowForOpening: tbHist,
            cut: cut,
            omslag: omslag,
            entity: entity,
            ownershipSlices: slices,
            entityIdOnRow: { $0.entityId }
        )

        return attachFinancialAverages(
            bundle,
            shape: shape,
            range: wins.window,
            calendar: calendar
        )
    }
}
