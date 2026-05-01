import Accounting
import Foundation

// Sum AE for *all* accounts whose code starts with `prefix`. Positive magnitudes.
@inlinable
public func aeMapForPrefix(
    bundle: StatementBundle,
    chart: CompiledChart,
    prefix: String
) -> [Int: Decimal] {
    guard let eb = bundle.entity?.byAccount else {
        return [:]
    }

    var out: [Int: Decimal] = [:]

    for n in chart.nodes where n.codes.code.hasPrefix(prefix) {
        if let m = eb[n.id] {
            for (eid, amt) in m {
                guard let oid = eid else {
                    continue
                }
                out[oid, default: 0] += (amt < 0 ? -amt : amt)
            }
        }
    }

    return out
}

public struct DrawingsBreakdown: Sendable {
    public let perGroupPerOwner: [(label: String, amounts: [Int: Decimal])]
    public let uncapturedAudit: [String: Decimal]

    public init(
        perGroupPerOwner: [(label: String, amounts: [Int: Decimal])],
        uncapturedAudit: [String: Decimal]
    ) {
        self.perGroupPerOwner = perGroupPerOwner
        self.uncapturedAudit = uncapturedAudit
    }
}

public struct EffectiveEquityDrawingsBranchRow: Sendable {
    public let ownerId: Int
    public let label: String
    public let detail: String?
    public let kind: EffectiveEquityBranchKind
    public let amount: Decimal

    public init(
        ownerId: Int,
        label: String,
        detail: String?,
        kind: EffectiveEquityBranchKind,
        amount: Decimal
    ) {
        self.ownerId = ownerId
        self.label = label
        self.detail = detail
        self.kind = kind
        self.amount = amount
    }
}

public struct EffectiveEquityDrawingsOwnerAmount: Sendable {
    public let ownerId: Int
    public let primary: Decimal
    public let direct: Decimal
    public let branches: [EffectiveEquityDrawingsBranchRow]

    public init(
        ownerId: Int,
        primary: Decimal,
        direct: Decimal,
        branches: [EffectiveEquityDrawingsBranchRow]
    ) {
        self.ownerId = ownerId
        self.primary = primary
        self.direct = direct
        self.branches = branches
    }
}

public struct EquityDrawingsBreakdownRow: Sendable {
    public let label: String
    public let amountsByOwner: [Int: Decimal]
    public let directAmountsByOwner: [Int: Decimal]
    public let total: Decimal
    public let branchRowsByOwner: [Int: [EffectiveEquityDrawingsBranchRow]]

    public init(
        label: String,
        amountsByOwner: [Int: Decimal],
        directAmountsByOwner: [Int: Decimal],
        total: Decimal,
        branchRowsByOwner: [Int: [EffectiveEquityDrawingsBranchRow]] = [:]
    ) {
        self.label = label
        self.amountsByOwner = amountsByOwner
        self.directAmountsByOwner = directAmountsByOwner
        self.total = total
        self.branchRowsByOwner = branchRowsByOwner
    }
}

/// Build per-post drawings detail; groups are matched by code prefix.
/// Any BEivKapPro* codes not captured end up in `uncapturedAudit` for visibility.
public func buildDrawingsBreakdown(
    bundle: StatementBundle,
    chart: CompiledChart,
    groups: [DrawingsGroup]
) -> DrawingsBreakdown {
    guard bundle.entity != nil else {
        return .init(
            perGroupPerOwner: [],
            uncapturedAudit: [:]
        )
    }

    var capturedIds = Set<Int>()
    var rows: [(String, [Int: Decimal])] = []

    for g in groups {
        var perOwner: [Int: Decimal] = [:]

        for n in chart.nodes where n.codes.code.hasPrefix(g.prefix) {
            capturedIds.insert(n.id)

            if let m = bundle.entity?.byAccount[n.id] {
                for (eid, amt) in m {
                    guard let oid = eid else {
                        continue
                    }

                    perOwner[oid, default: 0] += (amt < 0 ? -amt : amt)
                }
            }
        }

        if !perOwner.isEmpty {
            rows.append((g.label, perOwner))
        }
    }

    var uncaptured: [String: Decimal] = [:]

    for n in chart.nodes where n.codes.code.hasPrefix("BEivKapPro") {
        if capturedIds.contains(n.id) {
            continue
        }

        let signed = bundle.entity?.byAccount[n.id]?.values.reduce(Decimal(0), +) ?? 0
        if signed != 0 {
            uncaptured[n.codes.code] = signed
        }
    }

    return .init(
        perGroupPerOwner: rows,
        uncapturedAudit: uncaptured
    )
}

public func makeEquityDrawingsBreakdownReport(
    breakdown: DrawingsBreakdown,
    owners: [Int],
    deltas: [Int: OwnerDelta],
    asOf: Date,
    entities: EntityStore,
    digits: Int = 2
) throws -> EquityDrawingsBreakdownReport? {
    guard
        !breakdown.perGroupPerOwner.isEmpty
            || !breakdown.uncapturedAudit.isEmpty
    else {
        return nil
    }

    let names = ownerNameMap(entities)

    var rows: [EquityDrawingsBreakdownRow] = []
    var totalsByOwner: [Int: Decimal] = [:]
    var grandTotal: Decimal = 0

    for (label, perOwner) in breakdown.perGroupPerOwner {
        let effective = try buildEffectiveEquityBreakdownRow(
            label: label,
            directByOwner: perOwner,
            asOf: asOf,
            entities: entities,
            names: names
        )

        var primaryByOwner: [Int: Decimal] = [:]
        var directByOwner: [Int: Decimal] = [:]
        var branchRowsByOwner: [Int: [EffectiveEquityDrawingsBranchRow]] = [:]

        for node in effective.allocation.nodes {
            primaryByOwner[node.ownerId] = node.primary.onttrek
            directByOwner[node.ownerId] = node.direct.onttrek

            var branchRows: [EffectiveEquityDrawingsBranchRow] = []

            for branch in node.incoming {
                branchRows.append(
                    .init(
                        ownerId: node.ownerId,
                        label: branch.label,
                        detail: branch.detail,
                        kind: .incoming,
                        amount: branch.amounts.onttrek
                    )
                )
            }

            for branch in node.outgoing {
                branchRows.append(
                    .init(
                        ownerId: node.ownerId,
                        label: branch.label,
                        detail: branch.detail,
                        kind: .outgoing,
                        amount: branch.amounts.onttrek
                    )
                )
            }

            if !branchRows.isEmpty {
                branchRowsByOwner[node.ownerId] = branchRows
            }
        }

        let rowTotal = owners.reduce(into: Decimal(0)) { partial, oid in
            let value = primaryByOwner[oid] ?? 0
            partial += value
            totalsByOwner[oid, default: 0] += value
        }

        grandTotal += rowTotal

        rows.append(
            .init(
                label: label,
                amountsByOwner: primaryByOwner,
                directAmountsByOwner: directByOwner,
                total: rowTotal,
                branchRowsByOwner: branchRowsByOwner
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
