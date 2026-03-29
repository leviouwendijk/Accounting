import Foundation

public struct EquityOwnerDisplayTable: Sendable {
    public let rows: [EquityOwnerDisplayRow]

    public let actualTotalBegin: Decimal
    public let actualTotalStort: Decimal
    public let actualTotalOnttrek: Decimal
    public let actualTotalWinst: Decimal
    public let actualTotalEnd: Decimal

    public init(
        rows: [EquityOwnerDisplayRow],
        actualTotalBegin: Decimal,
        actualTotalStort: Decimal,
        actualTotalOnttrek: Decimal,
        actualTotalWinst: Decimal,
        actualTotalEnd: Decimal
    ) {
        self.rows = rows
        self.actualTotalBegin = actualTotalBegin
        self.actualTotalStort = actualTotalStort
        self.actualTotalOnttrek = actualTotalOnttrek
        self.actualTotalWinst = actualTotalWinst
        self.actualTotalEnd = actualTotalEnd
    }
}

public struct EquityOwnerDisplayRow: Sendable {
    public let label: String
    public let style: EquityOwnerDisplayStyle
    public let detail: String?

    public let begin: Decimal
    public let stort: Decimal
    public let onttrek: Decimal
    public let winst: Decimal
    public let end: Decimal

    public init(
        label: String,
        style: EquityOwnerDisplayStyle,
        detail: String?,
        begin: Decimal,
        stort: Decimal,
        onttrek: Decimal,
        winst: Decimal,
        end: Decimal
    ) {
        self.label = label
        self.style = style
        self.detail = detail
        self.begin = begin
        self.stort = stort
        self.onttrek = onttrek
        self.winst = winst
        self.end = end
    }
}

private struct ResolvedEquityOwnerPortion: Sendable {
    let ownerId: Int
    let portion: Decimal
    let ownerName: String
}

private struct ResolvedEquityOwnerDisplaySpec: Sendable {
    enum Kind: Sendable {
        case owner(ownerId: Int, ownerName: String)
        case composed(
            label: String,
            members: [ResolvedEquityOwnerPortion],
            style: EquityOwnerDisplayStyle
        )
    }

    let kind: Kind
}

public enum EquityOwnerDisplayPlanError: LocalizedError, Sendable {
    case invalidPortion(Decimal)
    case unresolvedOwnerRef(String)
    case missingOwnerID(String)

    public var errorDescription: String? {
        switch self {
        case .invalidPortion(let value):
            return "Owner display portion must be between 0 and 1, got \(value)."

        case .unresolvedOwnerRef(let ref):
            return "Could not resolve owner display reference '\(ref)'."

        case .missingOwnerID(let ref):
            return "Resolved owner display reference '\(ref)' but no stable owner id was found."
        }
    }
}

public func makeEquityOwnerDisplayTable(
    rows: PeriodRollforward,
    entities: EntityStore,
    cfg: EquityRollforwardConfig
) throws -> EquityOwnerDisplayTable {
    let names = ownerNameMap(entities)

    let resolvedSpecs = try resolveEquityOwnerDisplaySpecs(
        cfg.ownerDisplayPlan,
        entities: entities,
        fallbackOwners: rows.owners,
        names: names
    )

    let displayRows = resolvedSpecs.map { spec in
        makeEquityOwnerDisplayRow(
            spec,
            rows: rows
        )
    }

    var actualTotalBegin = Decimal(0)
    var actualTotalStort = Decimal(0)
    var actualTotalOnttrek = Decimal(0)
    var actualTotalWinst = Decimal(0)
    var actualTotalEnd = Decimal(0)

    for ownerId in rows.owners {
        let begin = rows.beginByOwner[ownerId] ?? 0
        let delta = rows.deltas[ownerId] ?? OwnerDelta(
            stort: 0,
            onttrek: 0,
            winst: 0
        )
        let end = rows.endByOwner[ownerId] ?? (begin + delta.delta)

        actualTotalBegin += begin
        actualTotalStort += delta.stort
        actualTotalOnttrek += delta.onttrek
        actualTotalWinst += delta.winst
        actualTotalEnd += end
    }

    return EquityOwnerDisplayTable(
        rows: displayRows,
        actualTotalBegin: actualTotalBegin,
        actualTotalStort: actualTotalStort,
        actualTotalOnttrek: actualTotalOnttrek,
        actualTotalWinst: actualTotalWinst,
        actualTotalEnd: actualTotalEnd
    )
}

private func resolveEquityOwnerDisplaySpecs(
    _ plan: EquityOwnerDisplayPlan?,
    entities: EntityStore,
    fallbackOwners: [Int],
    names: [Int?: String]
) throws -> [ResolvedEquityOwnerDisplaySpec] {
    guard let plan else {
        return fallbackOwners.map { ownerId in
            ResolvedEquityOwnerDisplaySpec(
                kind: .owner(
                    ownerId: ownerId,
                    ownerName: names[Int?(ownerId)] ?? "owner#\(ownerId)"
                )
            )
        }
    }

    let idIndex = entities.idIndex

    return try plan.rows.map { row in
        switch row {
        case .owner(let ref):
            let resolved = try entities.resolve(ref, at: nil)

            guard let ownerId = entities.idIndex[resolved.key] else {
                throw EquityOwnerDisplayPlanError.missingOwnerID(
                    resolved.key.identifier(displaying: .fullchain)
                )
            }

            let ownerName =
                names[Int?(ownerId)]
                ?? entities.byFull[resolved.key]?.displayName
                ?? resolved.key.identifier(displaying: .fullchain)

            return ResolvedEquityOwnerDisplaySpec(
                kind: .owner(
                    ownerId: ownerId,
                    ownerName: ownerName
                )
            )

        case .composed(let composed):
            let members = try composed.members.map { member in
                guard member.portion >= 0, member.portion <= 1 else {
                    throw EquityOwnerDisplayPlanError.invalidPortion(member.portion)
                }

                let resolved = try entities.resolve(member.owner, at: nil)
                guard let ownerId = idIndex[resolved.key] else {
                    throw EquityOwnerDisplayPlanError.missingOwnerID(member.owner.printable)
                }

                let ownerName =
                    names[Int?(ownerId)]
                    ?? entities.byFull[resolved.key]?.displayName
                    ?? resolved.key.identifier(displaying: .fullchain)

                return ResolvedEquityOwnerPortion(
                    ownerId: ownerId,
                    portion: member.portion,
                    ownerName: ownerName
                )
            }

            return ResolvedEquityOwnerDisplaySpec(
                kind: .composed(
                    label: composed.label,
                    members: members,
                    style: composed.style
                )
            )
        }
    }
}

private func makeEquityOwnerDisplayRow(
    _ spec: ResolvedEquityOwnerDisplaySpec,
    rows: PeriodRollforward
) -> EquityOwnerDisplayRow {
    switch spec.kind {
    case .owner(let ownerId, let ownerName):
        let begin = rows.beginByOwner[ownerId] ?? 0
        let delta = rows.deltas[ownerId] ?? OwnerDelta(
            stort: 0,
            onttrek: 0,
            winst: 0
        )
        let end = rows.endByOwner[ownerId] ?? (begin + delta.delta)

        return EquityOwnerDisplayRow(
            label: ownerName,
            style: .normal,
            detail: nil,
            begin: begin,
            stort: delta.stort,
            onttrek: delta.onttrek,
            winst: delta.winst,
            end: end
        )

    case .composed(let label, let members, let style):
        var begin = Decimal(0)
        var stort = Decimal(0)
        var onttrek = Decimal(0)
        var winst = Decimal(0)
        var end = Decimal(0)

        var detailParts: [String] = []

        for member in members {
            let ownerBegin = rows.beginByOwner[member.ownerId] ?? 0
            let ownerDelta = rows.deltas[member.ownerId] ?? OwnerDelta(
                stort: 0,
                onttrek: 0,
                winst: 0
            )
            let ownerEnd = rows.endByOwner[member.ownerId] ?? (ownerBegin + ownerDelta.delta)

            begin += ownerBegin * member.portion
            stort += ownerDelta.stort * member.portion
            onttrek += ownerDelta.onttrek * member.portion
            winst += ownerDelta.winst * member.portion
            end += ownerEnd * member.portion

            if member.portion == 1 {
                detailParts.append(member.ownerName)
            } else {
                detailParts.append("\(fmtPct(member.portion, digits: 2)) of \(member.ownerName)")
            }
        }

        return EquityOwnerDisplayRow(
            label: label,
            style: style,
            detail: detailParts.joined(separator: " + "),
            begin: begin,
            stort: stort,
            onttrek: onttrek,
            winst: winst,
            end: end
        )
    }
}
