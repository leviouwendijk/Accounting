import Accounting
extension RGSAssembler {
    public static func assemble(
        chart: CompiledChart,
        trialRows: [TrialBalanceRow],
        cut: AssembleCut,
        omslag: OmslagMode,
        for businessEntity: BusinessEntity = .vof,
        autoClose: Bool = true
    ) throws -> StatementBundle {
        let ch = try chart.ensuringIndex(enrichNodes: true, strict: false)
        guard let index = ch.index else { throw RGSAssemblerError.missingIndex }

        let maps = try RGSAssembler.makeMaps(from: ch)

        let targets = AutoCloseTargets(for: businessEntity)
        let resolved = try targets.resolve(in: index, validateWith: maps)

        let seed = RGSAssembler.seedLeafs(
            from: trialRows,
            using: index
        )
        try assertSeedSumsToZero(seed)

        let seedAE = RGSAssembler.seedLeafsAE(
            from: trialRows,
            using: index
        )

        if !autoClose {
            return try assembleNoAutoClose(
                chart: ch,
                index: index,
                maps: maps,
                cut: cut,
                omslag: omslag,
                businessEntity: businessEntity,
                seed: seed,
                seedAE: seedAE
            )
        } else {
            let ac = (
                niId: resolved.ni.id,
                niCode: resolved.ni.code,
                eqId: resolved.equity.id,
                eqCode: resolved.equity.code
            )

            return try assembleWithAutoClose(
                chart: ch,
                index: index,
                maps: maps,
                cut: cut,
                omslag: omslag,
                businessEntity: businessEntity,
                seed: seed,
                seedAE: seedAE,
                autoCloseTargets: ac
            )
        }
    }
}
