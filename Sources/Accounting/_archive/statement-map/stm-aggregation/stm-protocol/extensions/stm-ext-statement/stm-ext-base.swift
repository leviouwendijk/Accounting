import Foundation

public extension StatementAggregating {
    func netIncome(from incomeCube: StatementCube, periodIndex: Int = 0) -> Decimal {
        incomeCube.reduce(0) { acc, kv in
            (kv.key.periodIndex == periodIndex) ? acc + kv.value : acc
        }
    }

    func netIncomeByPartition(from incomeCube: StatementCube, periodIndex: Int = 0)
    -> [ [DimensionKey: DimensionValue] : Decimal ] {
        var byPart: [ [DimensionKey: DimensionValue] : Decimal ] = [:]
        for (k, amt) in incomeCube where k.periodIndex == periodIndex {
            byPart[k.partition, default: 0] += amt
        }
        return byPart
    }

    func injectCurrentPeriodResultIntoEquity(
        balanceCube: inout StatementCube,
        periodIndex: Int = 0,
        incomeCube: StatementCube
    ) {
        let equityRowId = StatementRowId(raw: "equity")
        let niByPart = netIncomeByPartition(from: incomeCube, periodIndex: periodIndex)

        if niByPart.isEmpty {
            let key = StatementCellKey(row: equityRowId, partition: [:], periodIndex: periodIndex)
            balanceCube[key, default: 0] += netIncome(from: incomeCube, periodIndex: periodIndex)
            return
        }

        for (part, ni) in niByPart {
            let key = StatementCellKey(row: equityRowId, partition: part, periodIndex: periodIndex)
            balanceCube[key, default: 0] += ni
        }
    }

    func balancePartitions(
        in cube: inout StatementCube,
        statement: StatementDef,
        partition: PartitionSpec
    ) {
        // Build list of unique partitions and periods present
        var partitions: Set<[DimensionKey: DimensionValue]> = []
        var periods: Set<Int> = []
        for key in cube.keys {
            partitions.insert(key.partition)
            periods.insert(key.periodIndex)
        }

        for periodIndex in periods {
            for part in partitions {
                // Sum across all rows for this partition/period
                var total: Decimal = 0
                for (key, val) in cube where key.periodIndex == periodIndex && key.partition == part {
                    total += val
                }
                guard total != 0 else { continue }

                // Emit synthetic balancing cell (negative of residual) so partition totals zero.
                // We keep balancing on its own special row id, so the visual layout can show it or hide it.
                let key = StatementCellKey(
                    row: StatementRowIds.balancing,
                    partition: part,
                    periodIndex: periodIndex
                )

                cube[key, default: 0] += (-total)
            }
        }
    }
}
