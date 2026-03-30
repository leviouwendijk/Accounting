import Foundation

public enum EffectiveEquityAllocationError: LocalizedError, Sendable {
    case missingOwnerID(String)

    public var errorDescription: String? {
        switch self {
        case .missingOwnerID(let ref):
            return "Resolved owner reference '\(ref)' but no stable owner id was found."
        }
    }
}

public func buildEffectiveEquityAllocation(
    directByOwner: [Int: EquityOwnerAmounts],
    asOf: Date,
    entities: EntityStore,
    names: [Int?: String]
) throws -> EffectiveEquityAllocation {
    var ownerIdSet = Set(directByOwner.keys)
    var displayOwnerIds = directByOwner.keys.sorted()

    func appendOwnerIfMissing(
        _ ownerId: Int
    ) {
        if ownerIdSet.insert(ownerId).inserted {
            displayOwnerIds.append(ownerId)
        }
    }

    var incomingByOwner: [Int: EquityOwnerAmounts] = [:]
    var outgoingByOwner: [Int: EquityOwnerAmounts] = [:]

    var incomingBranches: [Int: [EffectiveEquityBranch]] = [:]
    var outgoingBranches: [Int: [EffectiveEquityBranch]] = [:]

    let idIndex = entities.idIndex

    let sortedKeys = entities.byFull.keys.sorted {
        $0.identifier(displaying: .fullchain)
            < $1.identifier(displaying: .fullchain)
    }

    for key in sortedKeys {
        guard let def = entities.byFull[key] else {
            continue
        }

        guard let oe = def.ownerEquity else {
            continue
        }

        let divideEntries = oe.divideEntries(on: asOf)
        guard !divideEntries.isEmpty else {
            continue
        }

        guard let sourceOwnerId = idIndex[key] else {
            continue
        }

        let sourceBase = directByOwner[sourceOwnerId] ?? .zero
        if sourceBase == .zero {
            continue
        }

        appendOwnerIfMissing(sourceOwnerId)

        let sourceOwnerName = normalizeInlineDisplayText(
            names[Int?(sourceOwnerId)]
                ?? def.displayName
                ?? key.identifier(displaying: .fullchain)
        )

        for entry in divideEntries {
            let fraction = entry.fraction
            guard fraction != 0 else {
                continue
            }

            let resolved = try entities.resolve(entry.owner, at: nil)

            guard let targetOwnerId = idIndex[resolved.key] else {
                throw EffectiveEquityAllocationError.missingOwnerID(
                    resolved.key.identifier(displaying: .fullchain)
                )
            }

            guard targetOwnerId != sourceOwnerId else {
                continue
            }

            appendOwnerIfMissing(targetOwnerId)

            let targetOwnerName = normalizeInlineDisplayText(
                names[Int?(targetOwnerId)]
                    ?? entities.byFull[resolved.key]?.displayName
                    ?? resolved.key.identifier(displaying: .fullchain)
            )

            let allocated = sourceBase * fraction
            let pctText = fmtPct(fraction, digits: 2)

            outgoingByOwner[sourceOwnerId, default: .zero] =
                outgoingByOwner[sourceOwnerId, default: .zero] + allocated

            incomingByOwner[targetOwnerId, default: .zero] =
                incomingByOwner[targetOwnerId, default: .zero] + allocated

            incomingBranches[targetOwnerId, default: []].append(
                .init(
                    kind: .incoming,
                    sourceOwnerId: sourceOwnerId,
                    targetOwnerId: targetOwnerId,
                    label: "  from \(sourceOwnerName)",
                    detail: "\(pctText) of \(sourceOwnerName)",
                    amounts: allocated
                )
            )

            outgoingBranches[sourceOwnerId, default: []].append(
                .init(
                    kind: .outgoing,
                    sourceOwnerId: sourceOwnerId,
                    targetOwnerId: targetOwnerId,
                    label: "  to \(targetOwnerName)",
                    detail: "\(pctText) allocated to \(targetOwnerName)",
                    amounts: allocated * Decimal(-1)
                )
            )
        }
    }

    let nodes = displayOwnerIds.map { ownerId in
        let ownerName = normalizeInlineDisplayText(
            names[Int?(ownerId)] ?? "owner#\(ownerId)"
        )

        let direct = directByOwner[ownerId] ?? .zero
        let incoming = incomingByOwner[ownerId] ?? .zero
        let outgoing = outgoingByOwner[ownerId] ?? .zero
        let primary = direct - outgoing + incoming

        return EffectiveEquityOwnerNode(
            ownerId: ownerId,
            ownerName: ownerName,
            direct: direct,
            incoming: (incomingBranches[ownerId] ?? []).sorted { $0.label < $1.label },
            outgoing: (outgoingBranches[ownerId] ?? []).sorted { $0.label < $1.label },
            primary: primary
        )
    }

    return EffectiveEquityAllocation(
        ownerIds: displayOwnerIds,
        nodes: nodes
    )
}

private func buildDirectEquityOwnerAmounts(
    from rows: PeriodRollforward
) -> [Int: EquityOwnerAmounts] {
    Dictionary(
        uniqueKeysWithValues: rows.owners.map { ownerId in
            (
                ownerId,
                equityOwnerAmounts(
                    for: ownerId,
                    rows: rows
                )
            )
        }
    )
}

@inline(__always)
public func equityOwnerAmounts(
    for ownerId: Int,
    rows: PeriodRollforward
) -> EquityOwnerAmounts {
    let begin = rows.beginByOwner[ownerId] ?? 0
    let delta = rows.deltas[ownerId] ?? OwnerDelta(
        stort: 0,
        onttrek: 0,
        winst: 0
    )
    let end = rows.endByOwner[ownerId] ?? (begin + delta.delta)

    return .init(
        begin: begin,
        stort: delta.stort,
        onttrek: delta.onttrek,
        winst: delta.winst,
        end: end
    )
}

@inline(__always)
public func buildEffectiveEquityAllocation(
    rows: PeriodRollforward,
    entities: EntityStore,
    names: [Int?: String]
) throws -> EffectiveEquityAllocation {
    try buildEffectiveEquityAllocation(
        directByOwner: buildDirectEquityOwnerAmounts(from: rows),
        asOf: rows.asOf,
        entities: entities,
        names: names
    )
}
