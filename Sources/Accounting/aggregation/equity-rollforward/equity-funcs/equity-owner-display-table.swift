import Foundation

public struct EquityOwnerDisplaySectionTable: Sendable {
    public let rows: [EquityOwnerDisplayRow]

    public let totalBegin: Decimal
    public let totalStort: Decimal
    public let totalOnttrek: Decimal
    public let totalWinst: Decimal
    public let totalEnd: Decimal

    public init(
        rows: [EquityOwnerDisplayRow],
        totalBegin: Decimal,
        totalStort: Decimal,
        totalOnttrek: Decimal,
        totalWinst: Decimal,
        totalEnd: Decimal
    ) {
        self.rows = rows
        self.totalBegin = totalBegin
        self.totalStort = totalStort
        self.totalOnttrek = totalOnttrek
        self.totalWinst = totalWinst
        self.totalEnd = totalEnd
    }
}

public struct EquityOwnerDisplayTable: Sendable {
    public let sections: [EquityOwnerDisplaySectionTable]

    public let actualTotalBegin: Decimal
    public let actualTotalStort: Decimal
    public let actualTotalOnttrek: Decimal
    public let actualTotalWinst: Decimal
    public let actualTotalEnd: Decimal

    public init(
        sections: [EquityOwnerDisplaySectionTable],
        actualTotalBegin: Decimal,
        actualTotalStort: Decimal,
        actualTotalOnttrek: Decimal,
        actualTotalWinst: Decimal,
        actualTotalEnd: Decimal
    ) {
        self.sections = sections
        self.actualTotalBegin = actualTotalBegin
        self.actualTotalStort = actualTotalStort
        self.actualTotalOnttrek = actualTotalOnttrek
        self.actualTotalWinst = actualTotalWinst
        self.actualTotalEnd = actualTotalEnd
    }

    public var rows: [EquityOwnerDisplayRow] {
        sections.flatMap(\.rows)
    }
}

public struct EquityOwnerDisplayRow: Sendable {
    public let label: String
    public let style: EquityOwnerDisplayStyle
    public let detail: String?
    public let startsNewSection: Bool
    public let includeInSum: Bool

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
        includeInSum: Bool,
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
        self.includeInSum = includeInSum
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
        label: String?,
        includeInSum: Bool
    )
    case subtotal(
        label: String,
        members: [ResolvedEquityOwnerPortion],
        includeInSum: Bool
    )
}

// private struct OwnerDisplayAmounts: Sendable {
//     let begin: Decimal
//     let stort: Decimal
//     let onttrek: Decimal
//     let winst: Decimal
//     let end: Decimal

//     static let zero = OwnerDisplayAmounts(
//         begin: 0,
//         stort: 0,
//         onttrek: 0,
//         winst: 0,
//         end: 0
//     )

//     static func + (
//         lhs: OwnerDisplayAmounts,
//         rhs: OwnerDisplayAmounts
//     ) -> OwnerDisplayAmounts {
//         .init(
//             begin: lhs.begin + rhs.begin,
//             stort: lhs.stort + rhs.stort,
//             onttrek: lhs.onttrek + rhs.onttrek,
//             winst: lhs.winst + rhs.winst,
//             end: lhs.end + rhs.end
//         )
//     }

//     static func - (
//         lhs: OwnerDisplayAmounts,
//         rhs: OwnerDisplayAmounts
//     ) -> OwnerDisplayAmounts {
//         .init(
//             begin: lhs.begin - rhs.begin,
//             stort: lhs.stort - rhs.stort,
//             onttrek: lhs.onttrek - rhs.onttrek,
//             winst: lhs.winst - rhs.winst,
//             end: lhs.end - rhs.end
//         )
//     }

//     static func * (
//         lhs: OwnerDisplayAmounts,
//         rhs: Decimal
//     ) -> OwnerDisplayAmounts {
//         .init(
//             begin: lhs.begin * rhs,
//             stort: lhs.stort * rhs,
//             onttrek: lhs.onttrek * rhs,
//             winst: lhs.winst * rhs,
//             end: lhs.end * rhs
//         )
//     }
// }

// private struct StandardDisplayBranch: Sendable {
//     let label: String
//     let detail: String?
//     let amounts: OwnerDisplayAmounts
// }

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
    rows periodRows: PeriodRollforward,
    entities: EntityStore,
    cfg: EquityRollforwardConfig
) throws -> EquityOwnerDisplayTable {
    let names = ownerNameMap(entities)

    let displaySections = try makeDisplaySections(
        plan: cfg.ownerDisplayPlan,
        rows: periodRows,
        entities: entities,
        names: names
    )

    var actualTotalBegin = Decimal(0)
    var actualTotalStort = Decimal(0)
    var actualTotalOnttrek = Decimal(0)
    var actualTotalWinst = Decimal(0)
    var actualTotalEnd = Decimal(0)

    for ownerId in periodRows.owners {
        let begin = periodRows.beginByOwner[ownerId] ?? 0
        let delta = periodRows.deltas[ownerId] ?? OwnerDelta(
            stort: 0,
            onttrek: 0,
            winst: 0
        )
        let end = periodRows.endByOwner[ownerId] ?? (begin + delta.delta)

        actualTotalBegin += begin
        actualTotalStort += delta.stort
        actualTotalOnttrek += delta.onttrek
        actualTotalWinst += delta.winst
        actualTotalEnd += end
    }

    return EquityOwnerDisplayTable(
        sections: displaySections,
        actualTotalBegin: actualTotalBegin,
        actualTotalStort: actualTotalStort,
        actualTotalOnttrek: actualTotalOnttrek,
        actualTotalWinst: actualTotalWinst,
        actualTotalEnd: actualTotalEnd
    )
}

private func makeDisplaySections(
    plan: EquityOwnerDisplayPlan?,
    rows periodRows: PeriodRollforward,
    entities: EntityStore,
    names: [Int?: String]
) throws -> [EquityOwnerDisplaySectionTable] {
    if let plan {
        return try plan.sections.enumerated().map { element in
            let (sectionIndex, section) = element

            let renderedRows: [EquityOwnerDisplayRow]

            switch section.kind {
            case .standard:
                renderedRows = try makeStandardDisplayRows(
                    defaultOwnerIds: periodRows.owners,
                    rows: periodRows,
                    entities: entities,
                    names: names,
                    startsNewSectionOnFirstRow: sectionIndex > 0
                )

            case .manual:
                let resolved = try resolveManualSection(
                    section.rows,
                    entities: entities,
                    names: names
                )

                renderedRows = resolved.enumerated().map { rowElement in
                    let (rowIndex, spec) = rowElement

                    return makeEquityOwnerDisplayRow(
                        spec,
                        startsNewSection: sectionIndex > 0 && rowIndex == 0,
                        rows: periodRows
                    )
                }
            }

            return makeEquityOwnerDisplaySectionTable(
                rows: renderedRows
            )
        }
    }

    let renderedRows = makePlainOwnerDisplayRows(
        ownerIds: periodRows.owners,
        rows: periodRows,
        names: names,
        startsNewSectionOnFirstRow: false
    )

    return [
        makeEquityOwnerDisplaySectionTable(
            rows: renderedRows
        )
    ]
}

private func makePlainOwnerDisplayRows(
    ownerIds: [Int],
    rows: PeriodRollforward,
    names: [Int?: String],
    startsNewSectionOnFirstRow: Bool
) -> [EquityOwnerDisplayRow] {
    ownerIds.enumerated().map { element in
        let (rowIndex, ownerId) = element
        let ownerName = names[Int?(ownerId)] ?? "owner#\(ownerId)"

        return makeDisplayRow(
            label: ownerName,
            style: .normal,
            detail: nil,
            startsNewSection: startsNewSectionOnFirstRow && rowIndex == 0,
            includeInSum: true,
            amounts: amountsForOwner(ownerId, rows: rows)
        )
    }
}

private func resolveManualSection(
    _ rows: [EquityOwnerDisplayRowSpec],
    entities: EntityStore,
    names: [Int?: String]
) throws -> [ResolvedEquityOwnerDisplaySpec] {
    let idIndex = entities.idIndex

    return try rows.map { row in
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
                label: split.label.map(normalizeInlineDisplayText),
                includeInSum: split.includeInSum
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
                members: members,
                includeInSum: subtotal.includeInSum
            )
        }
    }
}

private func makeStandardDisplayRows(
    defaultOwnerIds: [Int],
    rows: PeriodRollforward,
    entities: EntityStore,
    names: [Int?: String],
    startsNewSectionOnFirstRow: Bool
) throws -> [EquityOwnerDisplayRow] {
    let allocation = try buildEffectiveEquityAllocation(
        rows: rows,
        entities: entities,
        names: names
    )

    var rendered: [EquityOwnerDisplayRow] = []

    for (index, node) in allocation.nodes.enumerated() {
        rendered.append(
            makeDisplayRow(
                label: node.ownerName,
                style: .normal,
                detail: nil,
                startsNewSection: startsNewSectionOnFirstRow && index == 0,
                includeInSum: true,
                amounts: node.primary
            )
        )

        let hasBranches =
            !node.incoming.isEmpty
            || !node.outgoing.isEmpty

        guard hasBranches else {
            continue
        }

        rendered.append(
            makeDisplayRow(
                label: "  \(node.ownerName) (direct)",
                style: .normal,
                detail: "Direct balance",
                startsNewSection: false,
                includeInSum: false,
                amounts: node.direct
            )
        )

        for branch in node.incoming {
            rendered.append(
                makeDisplayRow(
                    label: branch.label,
                    style: .normal,
                    detail: branch.detail,
                    startsNewSection: false,
                    includeInSum: false,
                    amounts: branch.amounts
                )
            )
        }

        for branch in node.outgoing {
            rendered.append(
                makeDisplayRow(
                    label: branch.label,
                    style: .normal,
                    detail: branch.detail,
                    startsNewSection: false,
                    includeInSum: false,
                    amounts: branch.amounts
                )
            )
        }
    }

    return rendered
}

private func makeEquityOwnerDisplaySectionTable(
    rows: [EquityOwnerDisplayRow]
) -> EquityOwnerDisplaySectionTable {
    var totalBegin = Decimal(0)
    var totalStort = Decimal(0)
    var totalOnttrek = Decimal(0)
    var totalWinst = Decimal(0)
    var totalEnd = Decimal(0)

    for row in rows where row.includeInSum {
        totalBegin += row.begin
        totalStort += row.stort
        totalOnttrek += row.onttrek
        totalWinst += row.winst
        totalEnd += row.end
    }

    return EquityOwnerDisplaySectionTable(
        rows: rows,
        totalBegin: totalBegin,
        totalStort: totalStort,
        totalOnttrek: totalOnttrek,
        totalWinst: totalWinst,
        totalEnd: totalEnd
    )
}

private func makeDisplayRows(
    plan: EquityOwnerDisplayPlan?,
    rows: PeriodRollforward,
    entities: EntityStore,
    names: [Int?: String]
) throws -> [EquityOwnerDisplayRow] {
    if let plan {
        var out: [EquityOwnerDisplayRow] = []

        for (sectionIndex, section) in plan.sections.enumerated() {
            switch section.kind {
            case .standard:
                out.append(
                    contentsOf: try makeStandardDisplayRows(
                        defaultOwnerIds: rows.owners,
                        rows: rows,
                        entities: entities,
                        names: names,
                        startsNewSectionOnFirstRow: sectionIndex > 0
                    )
                )

            case .manual:
                let resolved = try resolveManualSection(
                    section.rows,
                    entities: entities,
                    names: names
                )

                for (rowIndex, spec) in resolved.enumerated() {
                    out.append(
                        makeEquityOwnerDisplayRow(
                            spec,
                            startsNewSection: sectionIndex > 0 && rowIndex == 0,
                            rows: rows
                        )
                    )
                }
            }
        }

        return out
    }

    return makePlainOwnerDisplayRows(
        ownerIds: rows.owners,
        rows: rows,
        names: names,
        startsNewSectionOnFirstRow: false
    )
}

private func makeEquityOwnerDisplayRow(
    _ spec: ResolvedEquityOwnerDisplaySpec,
    startsNewSection: Bool,
    rows: PeriodRollforward
) -> EquityOwnerDisplayRow {
    switch spec {
    case .owner(let ownerId, let ownerName):
        return makeDisplayRow(
            label: ownerName,
            style: .normal,
            detail: nil,
            startsNewSection: startsNewSection,
            includeInSum: true,
            amounts: amountsForOwner(ownerId, rows: rows)
        )

    case .split(let ownerId, let ownerName, let portion, let label, let includeInSum):
        let direct = amountsForOwner(ownerId, rows: rows)
        let portioned = direct * portion

        let resolvedLabel = normalizeInlineDisplayText(
            label ?? "\(fmtPct(portion, digits: 2)) \(ownerName)"
        )

        return makeDisplayRow(
            label: resolvedLabel,
            style: .subtotal,
            detail: "\(fmtPct(portion, digits: 2)) of \(ownerName)",
            startsNewSection: startsNewSection,
            includeInSum: includeInSum,
            amounts: portioned
        )

    case .subtotal(let label, let members, let includeInSum):
        var total = EquityOwnerAmounts.zero
        var detailParts: [String] = []

        for member in members {
            let direct = amountsForOwner(
                member.ownerId,
                rows: rows
            )

            total = total + (direct * member.portion)

            if member.portion == 1 {
                detailParts.append(member.ownerName)
            } else {
                detailParts.append(
                    "\(fmtPct(member.portion, digits: 2)) of \(member.ownerName)"
                )
            }
        }

        return makeDisplayRow(
            label: label,
            style: .subtotal,
            detail: detailParts.joined(separator: " + "),
            startsNewSection: startsNewSection,
            includeInSum: includeInSum,
            amounts: total
        )
    }
}

private func amountsForOwner(
    _ ownerId: Int,
    rows: PeriodRollforward
) -> EquityOwnerAmounts {
    equityOwnerAmounts(
        for: ownerId,
        rows: rows
    )
}

// private func amountsForOwner(
//     _ ownerId: Int,
//     rows: PeriodRollforward
// ) -> OwnerDisplayAmounts {
//     let begin = rows.beginByOwner[ownerId] ?? 0
//     let delta = rows.deltas[ownerId] ?? OwnerDelta(
//         stort: 0,
//         onttrek: 0,
//         winst: 0
//     )
//     let end = rows.endByOwner[ownerId] ?? (begin + delta.delta)

//     return .init(
//         begin: begin,
//         stort: delta.stort,
//         onttrek: delta.onttrek,
//         winst: delta.winst,
//         end: end
//     )
// }

private func makeDisplayRow(
    label: String,
    style: EquityOwnerDisplayStyle,
    detail: String?,
    startsNewSection: Bool,
    includeInSum: Bool,
    // amounts: OwnerDisplayAmounts
    amounts: EquityOwnerAmounts
) -> EquityOwnerDisplayRow {
    EquityOwnerDisplayRow(
        label: label,
        style: style,
        detail: detail,
        startsNewSection: startsNewSection,
        includeInSum: includeInSum,
        begin: amounts.begin,
        stort: amounts.stort,
        onttrek: amounts.onttrek,
        winst: amounts.winst,
        end: amounts.end
    )
}
