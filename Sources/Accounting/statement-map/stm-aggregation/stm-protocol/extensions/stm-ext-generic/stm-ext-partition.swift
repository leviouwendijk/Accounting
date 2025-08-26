import Foundation

public extension StatementAggregating {
    @inline(__always)
    func evaluateFilters(_ filters: [DimensionFilter], on slice: DimensionSlice) -> Bool {
        guard !filters.isEmpty else { return true }
        for f in filters {
            let lhs = slice[f.key]
            switch f.op {
            case .equals:
                guard let v = f.values.first, lhs == v else { return false }
            case .notEquals:
                guard let v = f.values.first, lhs != v else { return false }
            case .in:
                guard let l = lhs, f.values.contains(l) else { return false }
            case .notIn:
                guard let l = lhs, !f.values.contains(l) else { return false }
            }
        }
        return true
    }

    @inline(__always)
    func makePartition(_ dims: DimensionSlice, spec: PartitionSpec?) -> [DimensionKey: DimensionValue] {
        guard let spec, !spec.keys.isEmpty else { return [:] }
        var out: [DimensionKey: DimensionValue] = [:]
        for k in spec.keys {
            if let v = dims[k] { out[k] = v }
        }
        // ensure stable ordering for hashing of StatementCellKey (we promise caller passes ordered keys)
        return out
    }
}
