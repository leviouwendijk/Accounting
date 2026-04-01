import Foundation
import Methods

public enum AssemblerKernel {}

extension AssemblerKernel {
    @inline(__always)
    public static func rollup(
        maps: RGSAssemblerResult,
        cut: AssembleCut,
        plan: AssemblerKernelSeedPlan
    ) -> AssemblerKernelSeedResult {
        var localCut = cut

        if let code = plan.netIncomePresentationCode {
            localCut.includeCodes.append(code)
        }

        if let code = plan.equityPresentationCode {
            localCut.includeCodes.append(code)
        }

        let netIncome = plan.incomeSeed.reduce(into: Decimal(0)) { acc, kv in
            if maps.kindById[kv.key] == .income {
                acc += kv.value
            }
        }

        var rolledIncome = RGSAssembler.rollupAmounts(
            plan.incomeSeed,
            parentById: maps.parentById
        )

        if !plan.suppressOverlay,
           plan.netIncomeOverlay != 0,
           let niId = plan.netIncomePresentationId {
            let niPatch = RGSAssembler.rollupAmounts(
                [niId: plan.netIncomeOverlay],
                parentById: maps.parentById
            )

            for (k, v) in niPatch where v != 0 {
                rolledIncome[k, default: 0] += v
            }
        }

        var rolledBalanceSeed = plan.balanceSeed

        if !plan.suppressOverlay,
           plan.netIncomeOverlay != 0,
           let niId = plan.netIncomePresentationId,
           let eqId = plan.equityPresentationId {
            rolledBalanceSeed[niId, default: 0] -= plan.netIncomeOverlay
            rolledBalanceSeed[eqId, default: 0] += plan.netIncomeOverlay
        }

        let rolledBalance = RGSAssembler.rollupAmounts(
            rolledBalanceSeed,
            parentById: maps.parentById
        )

        let breakdown: EntityBreakdown? = {
            guard var ae = plan.balanceSeedAE else {
                return nil
            }

            if !plan.suppressOverlay,
               plan.netIncomeOverlay != 0,
               let niId = plan.netIncomePresentationId,
               let eqId = plan.equityPresentationId {
                ae[AccEntKey(niId, nil), default: 0] -= plan.netIncomeOverlay
                ae[AccEntKey(eqId, nil), default: 0] += plan.netIncomeOverlay
            }

            let rolledAE = RGSAssembler.rollupByAccountPreservingEntity(
                ae,
                parentById: maps.parentById
            )

            let collapsedAE = RGSAssembler.collapseEntityDimension(
                rolledAE
            )

            entity_account_balance_mismatch(
                rolledBalance: rolledBalance,
                collapsedEntityBalance: collapsedAE,
                namesById: maps.nameById
            )
            .warn()

            var byAccount: [Int: [Int?: Decimal]] = [:]
            for (k, v) in rolledAE where v != 0 {
                byAccount[k.accountId, default: [:]][k.entityId, default: 0] += v
            }

            return .init(byAccount: byAccount)
        }()

        return .init(
            totalsIncome: rolledIncome,
            totalsBalance: rolledBalance,
            breakdown: breakdown,
            netIncome: netIncome,
            effectiveCut: localCut
        )
    }

    @inline(__always)
    public static func makeBundle(
        chart: CompiledChart,
        index: RGSIndex,
        maps: RGSAssemblerResult,
        cut: AssembleCut,
        omslag: OmslagMode,
        businessEntity: BusinessEntity,
        rolled: AssemblerKernelSeedResult
    ) throws -> StatementBundle {
        let (forcedIds, forcedChain) = RGSAssembler.makeForcedSets(
            index: index,
            cut: rolled.effectiveCut,
            parentById: maps.parentById
        )

        let labels = index.labelByGroupKey

        let balance = linesFor(
            .balance,
            roll: maps,
            totals: rolled.totalsBalance,
            labels: labels,
            cut: rolled.effectiveCut,
            forcedIds: forcedIds,
            forcedChain: forcedChain,
            omslag: omslag
        )

        let income = linesFor(
            .income,
            roll: maps,
            totals: rolled.totalsIncome,
            labels: labels,
            cut: rolled.effectiveCut,
            forcedIds: forcedIds,
            forcedChain: forcedChain,
            omslag: omslag
        )

        let preAnalyticsBundle = StatementBundle(
            balance: balance,
            income: income,
            totalsById: rolled.totalsBalance,
            entity: rolled.breakdown
        )

        let analytics = try RGSAssembler.makeAnalytics(
            chart: chart,
            bundle: preAnalyticsBundle,
            businessEntity: businessEntity,
            omslag: omslag,
            netIncome: rolled.netIncome
        )

        return StatementBundle(
            balance: balance,
            income: income,
            totalsById: rolled.totalsBalance,
            entity: rolled.breakdown,
            analytics: analytics
        )
    }

    @inline(__always)
    private static func entity_account_balance_mismatch(
        rolledBalance: [Int: Decimal],
        collapsedEntityBalance: [Int: Decimal],
        namesById: [Int: String],
        tolerance: Decimal = 0.01
    ) -> EntityMismatchDiagnostic {
        let ids = Set(rolledBalance.keys).union(
            collapsedEntityBalance.keys
        )

        var items: [EntityMismatchDiagnostic.Item] = []

        for id in ids.sorted() {
            let balance = rolledBalance[id] ?? 0
            let entityTotal = collapsedEntityBalance[id] ?? 0
            let diff = balance - entityTotal

            guard Compare.Number.Decimal.exceeds(
                diff,
                tolerance: tolerance,
                via: .direct
            ) else {
                continue
            }

            let name = namesById[id] ?? "node#\(id)"

            items.append(
                .init(
                    id: id,
                    name: name,
                    balance: balance,
                    entityTotal: entityTotal,
                    diff: diff
                )
            )
        }

        return .init(
            items: items
        )
    }
}
