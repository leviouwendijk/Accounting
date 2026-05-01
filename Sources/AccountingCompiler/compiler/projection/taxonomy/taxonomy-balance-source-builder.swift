import Accounting
import Foundation
import Primitives

public enum TaxonomyBalanceSourceMode: String, Sendable {
    case rawLeafTrialBalance
    case hybridClosingAndLeaf
}

public enum TaxonomyBalanceSourceBuilder {
    static func compileBalances(
        from output: NativeCompileOutput
    ) -> [String: Decimal] {
        compileHybridBalances(from: output)
    }

    static func currentPeriodBalances(
        from output: NativePeriodCompileOutput
    ) -> [String: Decimal] {
        currentPeriodHybridBalances(from: output)
    }

    static func previousPeriodBalances(
        from output: NativePeriodCompileOutput
    ) -> [String: Decimal]? {
        previousPeriodHybridBalances(from: output)
    }

    static func compileHybridBalances(
        from output: NativeCompileOutput
    ) -> [String: Decimal] {
        let closing = compileClosingBalances(from: output)
        let incomeLeaf = compileLeafIncomeBalances(from: output)

        return hybridBalances(
            chart: output.chart,
            closingBalances: closing,
            incomeLeafBalances: incomeLeaf
        )
    }

    static func currentPeriodHybridBalances(
        from output: NativePeriodCompileOutput
    ) -> [String: Decimal] {
        let closing = currentPeriodClosingBalances(from: output)
        let incomeLeaf = currentPeriodLeafIncomeBalances(from: output)

        return hybridBalances(
            chart: output.chart,
            closingBalances: closing,
            incomeLeafBalances: incomeLeaf
        )
    }

    static func previousPeriodHybridBalances(
        from output: NativePeriodCompileOutput
    ) -> [String: Decimal]? {
        guard
            let closing = previousPeriodClosingBalances(from: output),
            let incomeLeaf = previousPeriodLeafIncomeBalances(from: output)
        else {
            return nil
        }

        return hybridBalances(
            chart: output.chart,
            closingBalances: closing,
            incomeLeafBalances: incomeLeaf
        )
    }

    static func compileClosingBalances(
        from output: NativeCompileOutput
    ) -> [String: Decimal] {
        TaxonomyNativeBalanceExtractor.balances(output)
    }

    static func currentPeriodClosingBalances(
        from output: NativePeriodCompileOutput
    ) -> [String: Decimal] {
        TaxonomyNativeBalanceExtractor.balances(
            period: output.assembled.current,
            chart: output.chart
        )
    }

    static func previousPeriodClosingBalances(
        from output: NativePeriodCompileOutput
    ) -> [String: Decimal]? {
        output.assembled.previous.map {
            TaxonomyNativeBalanceExtractor.balances(
                period: $0,
                chart: output.chart
            )
        }
    }

    static func compileLeafIncomeBalances(
        from output: NativeCompileOutput
    ) -> [String: Decimal] {
        let rows = trialBalance(output.result.resolved)

        return leafBalances(
            chart: output.chart,
            trialRows: rows
        )
    }

    static func currentPeriodLeafIncomeBalances(
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

    static func previousPeriodLeafIncomeBalances(
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

    static func hybridBalances(
        chart: CompiledChart,
        closingBalances: [String: Decimal],
        incomeLeafBalances: [String: Decimal]
    ) -> [String: Decimal] {
        let maps = try? RGSAssembler.makeMaps(from: chart)
        let kindById = maps?.kindById ?? [:]

        var out: [String: Decimal] = [:]

        for node in chart.nodes {
            let code = node.codes.code
            guard !code.isEmpty else {
                continue
            }

            switch kindById[node.id] {
            case .some(.balance), .some(.cash), .some(.equity):
                if let amount = closingBalances[code], amount != 0 {
                    out[code] = amount
                }

            case .some(.income):
                if let amount = incomeLeafBalances[code], amount != 0 {
                    out[code] = amount
                }

            case .none:
                if let amount = closingBalances[code], amount != 0 {
                    out[code] = amount
                } else if let amount = incomeLeafBalances[code], amount != 0 {
                    out[code] = amount
                }
            }
        }

        return out
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
