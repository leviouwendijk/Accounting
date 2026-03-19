import Foundation

public extension StatementAggregating {
    @inline(__always)
    func absDecimal(_ d: Decimal) -> Decimal {
        return d < 0 ? -d : d
    }

    @inline(__always)
    func sumRow(_ cube: StatementCube, _ rowIdRaw: String, _ periodIndex: Int) -> Decimal {
        let rowId = StatementRowId(raw: rowIdRaw)
        return cube.reduce(0) { acc, kv in
            (kv.key.row == rowId && kv.key.periodIndex == periodIndex) ? acc + kv.value : acc
        }
    }

}
