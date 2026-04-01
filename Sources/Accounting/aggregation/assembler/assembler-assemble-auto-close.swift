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

    // @inline(__always)
    // public static func assembleWithAutoClose(
    //     chart: CompiledChart,
    //     index: RGSIndex,
    //     maps: RGSAssemblerResult,
    //     cut: AssembleCut,
    //     omslag: OmslagMode,
    //     businessEntity: BusinessEntity,
    //     seed: [Int: Decimal],
    //     seedAE: [AccEntKey: Decimal],
    //     autoCloseTargets: (
    //         niId: Int,
    //         niCode: String,
    //         eqId: Int,
    //         eqCode: String
    //     )
    // ) throws -> StatementBundle {
    //     var localCut = cut

    //     localCut.includeCodes.append(
    //         contentsOf: [
    //             autoCloseTargets.niCode,
    //             autoCloseTargets.eqCode
    //         ]
    //     )

    //     let ni = seed.reduce(into: Decimal(0)) { acc, kv in
    //         if maps.kindById[kv.key] == .income {
    //             acc += kv.value
    //         }
    //     }

    //     let manualAtNi = seed[autoCloseTargets.niId] ?? 0
    //     let manualAtEquity = seed[autoCloseTargets.eqId] ?? 0
    //     let hasManual = (manualAtNi != 0 || manualAtEquity != 0)

    //     if ni != 0 && hasManual {
    //         fputs(
    //             "warning: auto-close NI overlay present but manual postings detected at "
    //                 + "\(autoCloseTargets.niCode)=\(manualAtNi) and/or \(autoCloseTargets.eqCode)=\(manualAtEquity); "
    //                 + "overlay suppressed for this period.\n",
    //             stderr
    //         )
    //     }

    //     var seedWithAC = seed
    //     if !hasManual && ni != 0 {
    //         seedWithAC[autoCloseTargets.niId, default: 0] += (-ni)
    //         seedWithAC[autoCloseTargets.eqId, default: 0] += ni
    //     }

    //     var totalsIncome = RGSAssembler.rollupAmounts(
    //         seed,
    //         parentById: maps.parentById
    //     )

    //     if !hasManual && ni != 0 {
    //         let niPatch = RGSAssembler.rollupAmounts(
    //             [autoCloseTargets.niId: ni],
    //             parentById: maps.parentById
    //         )

    //         for (k, v) in niPatch where v != 0 {
    //             totalsIncome[k, default: 0] += v
    //         }
    //     }

    //     let totalsBalance = RGSAssembler.rollupAmounts(
    //         seedWithAC,
    //         parentById: maps.parentById
    //     )

    //     let (forcedIds, forcedChain) = makeForcedSets(
    //         index: index,
    //         cut: localCut,
    //         parentById: maps.parentById
    //     )

    //     let labels = index.labelByGroupKey

    //     let bs = linesFor(
    //         .balance,
    //         roll: maps,
    //         totals: totalsBalance,
    //         labels: labels,
    //         cut: localCut,
    //         forcedIds: forcedIds,
    //         forcedChain: forcedChain,
    //         omslag: omslag
    //     )

    //     let is_ = linesFor(
    //         .income,
    //         roll: maps,
    //         totals: totalsIncome,
    //         labels: labels,
    //         cut: localCut,
    //         forcedIds: forcedIds,
    //         forcedChain: forcedChain,
    //         omslag: omslag
    //     )

    //     var breakdown: EntityBreakdown? = nil
    //     do {
    //         let totalsAE_Income = RGSAssembler.rollupByAccountPreservingEntity(
    //             seedAE,
    //             parentById: maps.parentById
    //         )

    //         var byAccount: [Int: [Int?: Decimal]] = [:]
    //         for (k, v) in totalsAE_Income where v != 0 {
    //             byAccount[k.accountId, default: [:]][k.entityId, default: 0] += v
    //         }
    //         breakdown = .init(byAccount: byAccount)
    //     }

    //     let bundle = StatementBundle(
    //         balance: bs,
    //         income: is_,
    //         totalsById: totalsBalance,
    //         entity: breakdown
    //     )

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
    //         totalsById: totalsBalance,
    //         entity: breakdown,
    //         analytics: analytics
    //     )
    // }
}
