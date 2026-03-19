import Foundation

// Sum AE for *all* accounts whose code starts with `prefix`. Positive magnitudes.
@inlinable public func aeMapForPrefix(
    bundle: StatementBundle,
    chart: CompiledChart,
    prefix: String
) -> [Int: Decimal] {
    guard let eb = bundle.entity?.byAccount else { return [:] }
    var out: [Int: Decimal] = [:]
    for n in chart.nodes where n.codes.code.hasPrefix(prefix) {
        if let m = eb[n.id] {
            for (eid, amt) in m {
                guard let oid = eid else { continue }
                out[oid, default: 0] += (amt < 0 ? -amt : amt)
            }
        }
    }
    return out
}

public struct DrawingsBreakdown: Sendable {
    public let perGroupPerOwner: [(label: String, amounts: [Int: Decimal])]
    public let uncapturedAudit: [String: Decimal]   // codes under BEivKapPro* not matched by any prefix (signed totals)
}

/// Build per-post drawings detail; groups are matched by code prefix.
/// Any BEivKapPro* codes not captured end up in `uncapturedAudit` for visibility.
public func buildDrawingsBreakdown(
    bundle: StatementBundle,
    chart: CompiledChart,
    groups: [DrawingsGroup]
) -> DrawingsBreakdown {
    guard bundle.entity != nil else { return .init(perGroupPerOwner: [], uncapturedAudit: [:]) }

    // 1) Collect grouped rows
    var capturedIds = Set<Int>()
    var rows: [(String, [Int: Decimal])] = []
    for g in groups {
        var perOwner: [Int: Decimal] = [:]
        for n in chart.nodes where n.codes.code.hasPrefix(g.prefix) {
            capturedIds.insert(n.id)
            if let m = bundle.entity?.byAccount[n.id] {
                for (eid, amt) in m {
                    guard let oid = eid else { continue }
                    perOwner[oid, default: 0] += (amt < 0 ? -amt : amt)
                }
            }
        }
        if !perOwner.isEmpty { rows.append((g.label, perOwner)) }
    }

    // 2) Audit: anything under BEivKapPro* not captured by any group
    var uncaptured: [String: Decimal] = [:]
    for n in chart.nodes where n.codes.code.hasPrefix("BEivKapPro") {
        if capturedIds.contains(n.id) { continue }
        let signed = bundle.entity?.byAccount[n.id]?.values.reduce(Decimal(0), +) ?? 0
        if signed != 0 { uncaptured[n.codes.code] = signed }
    }

    return .init(perGroupPerOwner: rows, uncapturedAudit: uncaptured)
}
