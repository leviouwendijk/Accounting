import Foundation

extension RGSAssembler {
    public static func present(
        _ amount: Decimal,
        direction: Direction,
        mode: OmslagMode = .apply
    ) -> Decimal {
        guard mode == .apply else { return amount }
        switch direction {
        case .debit:  return amount
        case .credit: return -amount
        }
    }

    public static func presentedTotalsByL2(
        chart: CompiledChart,
        bundle: StatementBundle,
        buckets: L2Buckets,
        omslag: OmslagMode = .apply
    ) throws -> PresentedBalanceTotals {
        let maps = try makeMaps(from: chart)

        @inline(__always)
        func shown(_ id: Int) -> Decimal {
            let raw = bundle.totalsById[id] ?? 0
            let dir = maps.directionById[id] ?? .debit
            return present(raw, direction: dir, mode: omslag)
        }

        let a = buckets.assets.reduce(0) { $0 + shown($1) }
        let e = buckets.equity.map(shown) ?? 0
        let k = buckets.liabilities.reduce(0) { $0 + shown($1) }

        return PresentedBalanceTotals(assets: a, equity: e, liabilities: k)
    }
}
