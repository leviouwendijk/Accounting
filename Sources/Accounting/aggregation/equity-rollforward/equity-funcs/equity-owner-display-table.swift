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
    public let startsNewSection: Bool

    public let begin: Decimal
    public let stort: Decimal
    public let onttrek: Decimal
    public let winst: Decimal
    public let end: Decimal

    public init(
        label: String,
        style: EquityOwnerDisplayStyle,
        detail: String?,
        startsNewSection: Bool,
        begin: Decimal,
        stort: Decimal,
        onttrek: Decimal,
        winst: Decimal,
        end: Decimal
    ) {
        self.label = label
        self.style = style
        self.detail = detail
        self.startsNewSection = startsNewSection
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

private enum ResolvedEquityOwnerDisplaySpec: Sendable {
    case owner(
        ownerId: Int,
        ownerName: String
    )
    case split(
        ownerId: Int,
        ownerName: String,
        portion: Decimal,
        label: String?
    )
    case subtotal(
        label: String,
        members: [ResolvedEquityOwnerPortion]
    )
}

public enum EquityOwnerDisplayPlanError: LocalizedError, Sendable {
    case invalidPortion(Decimal)
    case missingOwnerID(String)

    public var errorDescription: String? {
        switch self {
        case .invalidPortion(let value):
            return "Owner display portion must be between 0 and 1, got \(value)."

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

    let displayRows = try makeDisplayRows(
        plan: cfg.ownerDisplayPlan,
        rows: rows,
        entities: entities,
        names: names
    )

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

private func makeDisplayRows(
    plan: EquityOwnerDisplayPlan?,
    rows: PeriodRollforward,
    entities: EntityStore,
    names: [Int?: String]
) throws -> [EquityOwnerDisplayRow] {
    let resolvedSections: [[ResolvedEquityOwnerDisplaySpec]]

    if let plan {
        resolvedSections = try resolveSections(
            plan.sections,
            entities: entities,
            names: names
        )
    } else {
        resolvedSections = [[
            rows.owners.map { ownerId in
                .owner(
                    ownerId: ownerId,
                    ownerName: names[Int?(ownerId)] ?? "owner#\(ownerId)"
                )
            }
        ].flatMap { $0 }]
    }

    var out: [EquityOwnerDisplayRow] = []

    for (sectionIndex, section) in resolvedSections.enumerated() {
        for (rowIndex, spec) in section.enumerated() {
            out.append(
                makeEquityOwnerDisplayRow(
                    spec,
                    startsNewSection: sectionIndex > 0 && rowIndex == 0,
                    rows: rows
                )
            )
        }
    }

    return out
}

private func resolveSections(
    _ sections: [EquityOwnerDisplaySection],
    entities: EntityStore,
    names: [Int?: String]
) throws -> [[ResolvedEquityOwnerDisplaySpec]] {
    let idIndex = entities.idIndex

    return try sections.map { section in
        try section.rows.map { row in
            switch row {
            case .owner(let ref):
                let resolved = try entities.resolve(ref, at: nil)

                guard let ownerId = idIndex[resolved.key] else {
                    throw EquityOwnerDisplayPlanError.missingOwnerID(
                        resolved.key.identifier(displaying: .fullchain)
                    )
                }

                let ownerName = normalizeInlineDisplayText(
                    names[Int?(ownerId)]
                        ?? entities.byFull[resolved.key]?.displayName
                        ?? resolved.key.identifier(displaying: .fullchain)
                )

                return .owner(
                    ownerId: ownerId,
                    ownerName: ownerName
                )

            case .split(let split):
                guard split.portion >= 0, split.portion <= 1 else {
                    throw EquityOwnerDisplayPlanError.invalidPortion(split.portion)
                }

                let resolved = try entities.resolve(split.owner, at: nil)

                guard let ownerId = idIndex[resolved.key] else {
                    throw EquityOwnerDisplayPlanError.missingOwnerID(
                        resolved.key.identifier(displaying: .fullchain)
                    )
                }

                let ownerName = normalizeInlineDisplayText(
                    names[Int?(ownerId)]
                        ?? entities.byFull[resolved.key]?.displayName
                        ?? resolved.key.identifier(displaying: .fullchain)
                )

                return .split(
                    ownerId: ownerId,
                    ownerName: ownerName,
                    portion: split.portion,
                    label: split.label.map(normalizeInlineDisplayText)
                )

            case .subtotal(let subtotal):
                let members = try subtotal.members.map { member in
                    guard member.portion >= 0, member.portion <= 1 else {
                        throw EquityOwnerDisplayPlanError.invalidPortion(member.portion)
                    }

                    let resolved = try entities.resolve(member.owner, at: nil)

                    guard let ownerId = idIndex[resolved.key] else {
                        throw EquityOwnerDisplayPlanError.missingOwnerID(
                            resolved.key.identifier(displaying: .fullchain)
                        )
                    }

                    let ownerName = normalizeInlineDisplayText(
                        names[Int?(ownerId)]
                            ?? entities.byFull[resolved.key]?.displayName
                            ?? resolved.key.identifier(displaying: .fullchain)
                    )

                    return ResolvedEquityOwnerPortion(
                        ownerId: ownerId,
                        portion: member.portion,
                        ownerName: ownerName
                    )
                }

                return .subtotal(
                    label: normalizeInlineDisplayText(subtotal.label),
                    members: members
                )
            }
        }
    }
}

private func makeEquityOwnerDisplayRow(
    _ spec: ResolvedEquityOwnerDisplaySpec,
    startsNewSection: Bool,
    rows: PeriodRollforward
) -> EquityOwnerDisplayRow {
    switch spec {
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
            startsNewSection: startsNewSection,
            begin: begin,
            stort: delta.stort,
            onttrek: delta.onttrek,
            winst: delta.winst,
            end: end
        )

    case .split(let ownerId, let ownerName, let portion, let label):
        let begin = (rows.beginByOwner[ownerId] ?? 0) * portion
        let delta = rows.deltas[ownerId] ?? OwnerDelta(
            stort: 0,
            onttrek: 0,
            winst: 0
        )
        let end = (rows.endByOwner[ownerId] ?? 0) * portion

        let resolvedLabel = normalizeInlineDisplayText(
            label ?? "\(fmtPct(portion, digits: 2)) \(ownerName)"
        )

        return EquityOwnerDisplayRow(
            label: resolvedLabel,
            style: .subtotal,
            detail: "\(fmtPct(portion, digits: 2)) of \(ownerName)",
            startsNewSection: startsNewSection,
            begin: begin,
            stort: delta.stort * portion,
            onttrek: delta.onttrek * portion,
            winst: delta.winst * portion,
            end: end
        )

    case .subtotal(let label, let members):
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
            style: .subtotal,
            detail: detailParts.joined(separator: " + "),
            startsNewSection: startsNewSection,
            begin: begin,
            stort: stort,
            onttrek: onttrek,
            winst: winst,
            end: end
        )
    }
}
