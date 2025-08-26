import Foundation

public extension StatementAggregating {
    func applyMateriality(
        in cube: inout StatementCube,
        statement: StatementDef,
        partition: PartitionSpec?
    ) {

        let OTHER_TOKEN = "__other__"
        // Only applies when there is partitioning; if no partition, row-level threshold doesn't change presentation here.
        guard let _ = partition else { return }

        // Group cells by (row, periodIndex)
        let groups: [RowPeriodKey: [StatementCellKey]] =
            Dictionary(grouping: cube.keys) { (k: StatementCellKey) in
                RowPeriodKey(row: k.row, period: k.periodIndex)
            }

        for (rp, keys) in groups {
            guard let row = statement.rows.first(where: { $0.id == rp.row }),
                  let thresh = row.materialityThreshold, thresh > 0 else { continue }

            var sumOther: Decimal = 0
            var toRemove: [StatementCellKey] = []

            for key in keys {
                let amt = cube[key] ?? 0
                if absDecimal(amt) < thresh {
                    sumOther += amt
                    toRemove.append(key)
                }
            }

            for k in toRemove { cube.removeValue(forKey: k) }

            if sumOther != 0 {
                var otherPart: [DimensionKey: DimensionValue] = [:]
                if let spec = partition {
                    for k in spec.keys { otherPart[k] = .text(OTHER_TOKEN) }
                }
                let otherKey = StatementCellKey(row: rp.row, partition: otherPart, periodIndex: rp.period)
                cube[otherKey, default: 0] += sumOther
            }
        }
    }
}
