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

    // @inline(__always)
    // public static func assembleNoAutoClose(
    //     chart: CompiledChart,
    //     index: RGSIndex,
    //     maps: RGSAssemblerResult,
    //     cut: AssembleCut,
    //     omslag: OmslagMode,
    //     businessEntity: BusinessEntity,
    //     seed: [Int: Decimal],
    //     seedAE: [AccEntKey: Decimal]
    // ) throws -> StatementBundle {
    //     let totalsAE = RGSAssembler.rollupByAccountPreservingEntity(
    //         seedAE,
    //         parentById: maps.parentById
    //     )
    //     let totalsPlain = RGSAssembler.collapseEntityDimension(
    //         totalsAE
    //     )

    //     let (forcedIds, forcedChain) = makeForcedSets(
    //         index: index,
    //         cut: cut,
    //         parentById: maps.parentById
    //     )

    //     let labels = index.labelByGroupKey

    //     let bs = linesFor(
    //         .balance,
    //         roll: maps,
    //         totals: totalsPlain,
    //         labels: labels,
    //         cut: cut,
    //         forcedIds: forcedIds,
    //         forcedChain: forcedChain,
    //         omslag: omslag
    //     )

    //     let is_ = linesFor(
    //         .income,
    //         roll: maps,
    //         totals: totalsPlain,
    //         labels: labels,
    //         cut: cut,
    //         forcedIds: forcedIds,
    //         forcedChain: forcedChain,
    //         omslag: omslag
    //     )

    //     var breakdown: EntityBreakdown? = nil
    //     do {
    //         var byAccount: [Int: [Int?: Decimal]] = [:]
    //         for (k, v) in totalsAE where v != 0 {
    //             byAccount[k.accountId, default: [:]][k.entityId, default: 0] += v
    //         }
    //         breakdown = .init(byAccount: byAccount)
    //     }

    //     let bundle = StatementBundle(
    //         balance: bs,
    //         income: is_,
    //         totalsById: totalsPlain,
    //         entity: breakdown
    //     )

    //     let ni = seed.reduce(into: Decimal(0)) { acc, kv in
    //         if maps.kindById[kv.key] == .income {
    //             acc += kv.value
    //         }
    //     }

    //     let analytics = try makeAnalytics(
    //         chart: chart,
    //         bundle: bundle,
    //         businessEntity: businessEntity,
    //         omslag: omslag,
    //         netIncome: ni
    //     )

    //     return StatementBundle(
    //         balance: bs,
    //         income: is_,
    //         totalsById: totalsPlain,
    //         entity: breakdown,
    //         analytics: analytics
    //     )
    // }
}
