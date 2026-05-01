import Accounting
import Foundation

extension RGSAssembler {
    @inline(__always)
    public static func assembleWithAutoClose(
        chart: CompiledChart,
        index: RGSIndex,
        maps: RGSAssemblerResult,
        cut: AssembleCut,
        omslag: OmslagMode,
        businessEntity: BusinessEntity,
        seed: [Int: Decimal],
        seedAE: [AccEntKey: Decimal],
        autoCloseTargets: (
            niId: Int,
            niCode: String,
            eqId: Int,
            eqCode: String
        )
    ) throws -> StatementBundle {
        let ni = seed.reduce(into: Decimal(0)) { acc, kv in
            if maps.kindById[kv.key] == .income {
                acc += kv.value
            }
        }

        let manualAtNi = seed[autoCloseTargets.niId] ?? 0
        let manualAtEquity = seed[autoCloseTargets.eqId] ?? 0
        let hasManual = (manualAtNi != 0 || manualAtEquity != 0)

        if ni != 0 && hasManual {
            fputs(
                "warning: auto-close NI overlay present but manual postings detected at "
                    + "\(autoCloseTargets.niCode)=\(manualAtNi) and/or \(autoCloseTargets.eqCode)=\(manualAtEquity); "
                    + "overlay suppressed for this period.\n",
                stderr
            )
        }

        let rolled = AssemblerKernel.rollup(
            maps: maps,
            cut: cut,
            plan: .init(
                incomeSeed: seed,
                balanceSeed: seed,
                balanceSeedAE: seedAE,
                netIncomePresentationId: autoCloseTargets.niId,
                netIncomePresentationCode: autoCloseTargets.niCode,
                equityPresentationId: autoCloseTargets.eqId,
                equityPresentationCode: autoCloseTargets.eqCode,
                netIncomeOverlay: ni,
                suppressOverlay: hasManual
            )
        )

        return try AssemblerKernel.makeBundle(
            chart: chart,
            index: index,
            maps: maps,
            cut: cut,
            omslag: omslag,
            businessEntity: businessEntity,
            rolled: rolled
        )
    }
}
