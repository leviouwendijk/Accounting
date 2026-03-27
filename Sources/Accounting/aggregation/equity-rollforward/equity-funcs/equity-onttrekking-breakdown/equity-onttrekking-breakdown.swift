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

public func makeEquityDrawingsBreakdownReport(
    breakdown: DrawingsBreakdown,
    owners: [Int],
    deltas: [Int: OwnerDelta],
    digits: Int = 2
) -> EquityDrawingsBreakdownReport? {
    guard
        !breakdown.perGroupPerOwner.isEmpty
            || !breakdown.uncapturedAudit.isEmpty
    else {
        return nil
    }

    var rows: [EquityDrawingsBreakdownRow] = []
    var totalsByOwner: [Int: Decimal] = [:]
    var grandTotal: Decimal = 0

    for (label, perOwner) in breakdown.perGroupPerOwner {
        let rowTotal = owners.reduce(into: Decimal(0)) { partial, oid in
            let value = perOwner[oid] ?? 0
            partial += value
            totalsByOwner[oid, default: 0] += value
        }

        grandTotal += rowTotal

        rows.append(
            .init(
                label: label,
                amountsByOwner: perOwner,
                total: rowTotal
            )
        )
    }

    let reconcilesWithOnttrek = owners.allSatisfy { oid in
        let onttrek = deltas[oid]?.onttrek ?? 0
        let detailed = totalsByOwner[oid] ?? 0
        return roundD(
            onttrek - detailed,
            digits: digits
        ) == 0
    }

    return .init(
        owners: owners,
        rows: rows,
        totalsByOwner: totalsByOwner,
        grandTotal: grandTotal,
        uncapturedAudit: breakdown.uncapturedAudit,
        reconcilesWithOnttrek: reconcilesWithOnttrek
    )
}
