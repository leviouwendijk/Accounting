import Foundation
import Methods

extension RGSAssembler {
    @inline(__always)
    public static func assertSeedSumsToZero(_ seed: [Int: Decimal]) throws {
        let sum = seed.values.reduce(0, +)
        if sum != 0 { throw RGSAssemblerError.seedTotalsNotZero(sum) }
    }

    /// Warn/throw if not balanced (by L2 sums).
    public static func assertBalancedByL2(
        chart: CompiledChart,
        bundle: StatementBundle,
        equityCode: String = "BEiv",
        eps: Decimal = 0
    ) throws {
        let buckets = try makeL2Buckets(chart: chart, defaultEquityCode: equityCode)
        let t = try presentedTotalsByL2(chart: chart, bundle: bundle, buckets: buckets, omslag: .apply)

        // Assets == Equity + Liabilities  (display magnitudes)
        let diff = t.assets - (t.equity + t.liabilities)
        // if diff != 0 && abs((diff as NSDecimalNumber).doubleValue) > (eps as NSDecimalNumber).doubleValue {
        if Compare.Number.Decimal.exceeds(
            diff,
            tolerance: eps,
            via: .direct
        ) {
            throw RGSAssemblerError.unbalanced(diff: diff, assets: t.assets, equity: t.equity, liabilities: t.liabilities, eps: eps)
        }
    }

    /// Optional extra: raw check that Debit-L2 sum equals Credit-L2 sum in raw signs.
    public static func assertBalancedByL2Raw(
        chart: CompiledChart,
        bundle: StatementBundle,
        equityCode: String = "BEiv",
        eps: Decimal = 0
    ) throws {
        // let maps = try makeMaps(from: chart)
        let b = try makeL2Buckets(chart: chart, defaultEquityCode: equityCode)

        @inline(__always)
        func raw(_ id: Int) -> Decimal { bundle.totalsById[id] ?? 0 }

        let debitSum  = b.assets.reduce(0) { $0 + raw($1) }        // typically positive
        let creditSum = (b.liabilities + (b.equity.map{[$0]} ?? []))
            .reduce(0) { $0 + raw($1) }                           // typically negative

        let diff = debitSum + creditSum
        // if diff != 0 && abs((diff as NSDecimalNumber).doubleValue) > (eps as NSDecimalNumber).doubleValue {
        if Compare.Number.Decimal.exceeds(
            diff,
            tolerance: eps,
            via: .direct
        ) {
            throw RGSAssemblerError.unbalanced(diff: diff, assets: debitSum, equity: 0, liabilities: creditSum, eps: eps)
        }
    }
}
