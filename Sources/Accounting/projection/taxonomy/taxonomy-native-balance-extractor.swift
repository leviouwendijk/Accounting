import Foundation

enum TaxonomyNativeBalanceExtractor {
    static func balances(
        chart: CompiledChart,
        totalsById: [Int: Decimal]
    ) -> [String: Decimal] {
        let codeById = Dictionary(
            uniqueKeysWithValues: chart.nodes.map { ($0.id, $0.codes.code) }
        )

        var out: [String: Decimal] = [:]
        for (id, amount) in totalsById where amount != 0 {
            guard let code = codeById[id], !code.isEmpty else { continue }
            out[code, default: 0] += amount
        }
        return out
    }

    static func balances(
        _ output: NativeCompileOutput
    ) -> [String: Decimal] {
        balances(
            chart: output.chart,
            totalsById: output.bundle.totalsById
        )
    }

    static func balances(
        period: PeriodAssembleResultPeriod,
        chart: CompiledChart
    ) -> [String: Decimal] {
        balances(
            chart: chart,
            totalsById: period.bundle.totalsById
        )
    }
}
