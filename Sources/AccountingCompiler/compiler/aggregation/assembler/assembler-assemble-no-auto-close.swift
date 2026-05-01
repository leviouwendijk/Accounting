import Accounting
import Foundation

extension RGSAssembler {
    @inline(__always)
    public static func assembleNoAutoClose(
        chart: CompiledChart,
        index: RGSIndex,
        maps: RGSAssemblerResult,
        cut: AssembleCut,
        omslag: OmslagMode,
        businessEntity: BusinessEntity,
        seed: [Int: Decimal],
        seedAE: [AccEntKey: Decimal]
    ) throws -> StatementBundle {
        let rolled = AssemblerKernel.rollup(
            maps: maps,
            cut: cut,
            plan: .init(
                incomeSeed: seed,
                balanceSeed: seed,
                balanceSeedAE: seedAE,
                netIncomeOverlay: 0,
                suppressOverlay: true
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
