import Foundation

public extension StatementAggregating {
    func bucket(
        _ postings: [NormalizedPosting],
        into cube: inout StatementCube,
        periodIndex: Int,
        matchers: [RowMatcher],
        partition: PartitionSpec?
    ) {
        for p in postings {
            // Find all rows this posting contributes to (normally one; union semantics allow multi if you want)
            for m in matchers where m.predicate(p) {
                let partKey = makePartition(p.dims, spec: partition)
                let key = StatementCellKey(row: m.row.id, partition: partKey, periodIndex: periodIndex)
                cube[key, default: 0] += p.amount
            }
        }
    }
}
