import Foundation

public struct RowPeriodKey: Hashable {
    public let row: StatementRowId
    public let period: Int
}

public struct RowMatcher {
    public let row: StatementRowDef
    public let predicate: (NormalizedPosting) -> Bool
}

public func compileMatchers(for statement: StatementDef) throws -> [RowMatcher] {
    return statement.rows.map { row in
        // Pre-build one fast predicate per row. Union semantics: posting matches if any rule matches.
        let rules = row.rgs
        let pred: (NormalizedPosting) -> Bool = { p in
            for r in rules {
                if matches(rule: r, posting: p) { return true }
            }
            return false
        }
        return RowMatcher(row: row, predicate: pred)
    }
}

@inline(__always)
public func matches(rule r: RGSMappingRule, posting p: NormalizedPosting) -> Bool {
    // Include codes
    if let codes = r.includeCodes, !codes.isEmpty {
        if codes.contains(p.rgsCode) == false { return false }
    }
    // Include prefixes
    if let prefs = r.includePrefixes, !prefs.isEmpty {
        var ok = false
        for pre in prefs { if p.rgsCode.hasPrefix(pre) { ok = true; break } }
        if !ok { return false }
    }
    // Level constraint
    if let lvl = r.includeLevel {
        guard let pl = p.rgsLevel, pl == lvl else { return false }
    }
    // Natural direction (account’s inherent DR/CR side)
    if let dir = r.filterDirection {
        guard p.naturalSide == dir else { return false }
    }
    return true
}

// MARK: - Dimension filters

@inline(__always)
public func evaluateFilters(_ filters: [DimensionFilter], on slice: DimensionSlice) -> Bool {
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

// MARK: - Bucketing

public func bucket(
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

@inline(__always)
public func makePartition(_ dims: DimensionSlice, spec: PartitionSpec?) -> [DimensionKey: DimensionValue] {
    guard let spec, !spec.keys.isEmpty else { return [:] }
    var out: [DimensionKey: DimensionValue] = [:]
    for k in spec.keys {
        if let v = dims[k] { out[k] = v }
    }
    // ensure stable ordering for hashing of StatementCellKey (we promise caller passes ordered keys)
    return out
}

// MARK: - Materiality

/// We aggregate small absolute values into a special “Other” partition value per row.
/// This keeps row totals intact but avoids clutter across many tiny partitions.
/// UI can translate the magic token to a label like "Other".
public let OTHER_TOKEN = "__other__"

public func applyMateriality(
    in cube: inout StatementCube,
    statement: StatementDef,
    partition: PartitionSpec?
) {
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

@inline(__always)
public func absDecimal(_ d: Decimal) -> Decimal {
    return d < 0 ? -d : d
}

// MARK: - Partition balancing (document-splitting style)

/// For Balance Sheet with partitioning: make each partition sum to zero across all rows.
/// We add a synthetic balancing cell into a reserved "Balancing" row if residuals exist.
public let BALANCING_ROW_ID = StatementRowId(raw: "__balancing__")

public func balancePartitions(
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
            let key = StatementCellKey(row: BALANCING_ROW_ID, partition: part, periodIndex: periodIndex)
            cube[key, default: 0] += (-total)
        }
    }
}
