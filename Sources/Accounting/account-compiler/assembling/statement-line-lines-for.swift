import Foundation

public func linesFor(
    _ kind: StatementKind,
    roll: RGSAssemblerResult,
    totals: [Int: Decimal],
    labels: [String: String],
    cut: AssembleCut,
    forcedIds: Set<Int>,
    forcedChain: Set<Int>,
    omslag: OmslagMode
) -> [StatementLine] {

    var rows: [
        (
            id: Int,
            key: String,
            lvl: Int,
            raw: Decimal,
            shown: Decimal,
            direction: Direction,
            orientation: AccountOrientation
        )
    ] = []

    for (id, key) in roll.sortKeyById {
        guard roll.kindById[id] == kind else {
            continue
        }

        let lvl = key.isEmpty ? 1 : key.split(separator: ".").count
        guard lvl <= cut.target.rawValue else {
            continue
        }

        let raw = totals[id] ?? 0

        let isForced = forcedIds.contains(id) || forcedChain.contains(id)
        if raw == 0, cut.omitZerosBeyondLevel1, lvl > 1, !isForced {
            continue
        }

        let direction = roll.directionById[id] ?? .debit

        let orientation = checkBalanceOrientation(
            direction: direction,
            balance: NSDecimalNumber(decimal: raw).doubleValue
        )

        let shown = RGSAssembler.present(
            raw,
            direction: direction,
            mode: omslag
        )

        rows.append(
            (
                id: id,
                key: key,
                lvl: lvl,
                raw: raw,
                shown: shown,
                direction: direction,
                orientation: orientation
            )
        )
    }

    rows.sort {
        RGSNodeSortingCode(key: $0.key) < RGSNodeSortingCode(key: $1.key)
    }

    return rows.map { row in
        StatementLine(
            label: labels[row.key] ?? roll.nameById[row.id] ?? row.key,
            rawAmount: row.raw,
            amount: row.shown,
            id: row.id,
            level: row.lvl,
            direction: row.direction,
            orientation: row.orientation
        )
    }
}
