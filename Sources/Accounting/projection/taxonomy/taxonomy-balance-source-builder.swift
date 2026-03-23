import Foundation
import Primitives

public enum TaxonomyBalanceSourceMode: String, Sendable {
    case rawLeafTrialBalance
}

public enum TaxonomyBalanceSourceBuilder {
    static func compileBalances(
        from output: NativeCompileOutput
    ) -> [String: Decimal] {
        let rows = trialBalance(output.result.resolved)

        return leafBalances(
            chart: output.chart,
            trialRows: rows
        )
    }

    static func currentPeriodBalances(
        from output: NativePeriodCompileOutput
    ) -> [String: Decimal] {
        let rows = trialBalance(
            filterEntries(
                output.result.resolved,
                within: output.assembled.current.range
            )
        )

        return leafBalances(
            chart: output.chart,
            trialRows: rows
        )
    }

    static func previousPeriodBalances(
        from output: NativePeriodCompileOutput
    ) -> [String: Decimal]? {
        guard let previous = output.assembled.previous else {
            return nil
        }

        let rows = trialBalance(
            filterEntries(
                output.result.resolved,
                within: previous.range
            )
        )

        return leafBalances(
            chart: output.chart,
            trialRows: rows
        )
    }

    static func leafBalances(
        chart: CompiledChart,
        trialRows: [TrialBalanceRow]
    ) -> [String: Decimal] {
        guard let index = chart.index else {
            return [:]
        }

        let seed = RGSAssembler.seedLeafs(
            from: trialRows,
            using: index
        )

        let parentIds = parentIdSet(chart: chart)

        let codeById = Dictionary(
            uniqueKeysWithValues: chart.nodes.map { ($0.id, $0.codes.code) }
        )

        var out: [String: Decimal] = [:]

        for (id, amount) in seed where amount != 0 {
            if parentIds.contains(id) {
                continue
            }

            guard let code = codeById[id], !code.isEmpty else {
                continue
            }

            out[code, default: 0] += amount
        }

        return out
    }

    static func parentCodes(
        chart: CompiledChart
    ) -> Set<String> {
        let parentIds = parentIdSet(chart: chart)
        let codeById = Dictionary(
            uniqueKeysWithValues: chart.nodes.map { ($0.id, $0.codes.code) }
        )

        return Set(
            parentIds.compactMap { codeById[$0] }.filter { !$0.isEmpty }
        )
    }

    private static func parentIdSet(
        chart: CompiledChart
    ) -> Set<Int> {
        guard let index = chart.index else {
            return []
        }

        let maps = try? RGSAssembler.makeMaps(from: chart)

        var out = Set<Int>(Array(maps?.parentById.values ?? [:].values))

        for node in chart.nodes {
            let key = node.xlsx?.sorting.key ?? node.codes.code
            var curKey: String? = key

            while let current = curKey {
                guard
                    let parentKey = RGSNodeSortingCode(key: current).parentKeyString,
                    !parentKey.isEmpty
                else {
                    break
                }

                if let parentId = index.bySortKey[parentKey] {
                    out.insert(parentId)
                    curKey = parentKey
                } else {
                    break
                }
            }
        }

        return out
    }
}
