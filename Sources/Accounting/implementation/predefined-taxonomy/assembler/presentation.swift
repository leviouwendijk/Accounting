import Foundation

public struct RGSPresentationLine: Sendable {
    public let label: String
    public let amount: Decimal
    public let id: Int
    public let level: Int
    
    public init(
        label: String,
        amount: Decimal,
        id: Int,
        level: Int
    ) {
        self.label = label
        self.amount = amount
        self.id = id
        self.level = level
    }
}

public func linesFor(
    _ kind: StatementKind,
    roll: RGSAssemblerResult,
    totals: [Int: Decimal],
    labels: [String:String],
    cut: AssembleCut,
    forcedIds: Set<Int>,
    forcedChain: Set<Int>,
    omslag: OmslagMode
) -> [RGSPresentationLine] {

    var rows: [(id:Int, key:String, lvl:Int, amt:Decimal)] = []

    for (id, key) in roll.sortKeyById {
        guard roll.kindById[id] == kind else { continue }
        let lvl = key.isEmpty ? 1 : key.split(separator: ".").count

        let raw = totals[id] ?? 0
        let shown = RGSAssembler.present(raw, direction: roll.directionById[id] ?? .debit, mode: omslag)

        let isForced = forcedIds.contains(id) || forcedChain.contains(id)
        let depthOK = (lvl <= cut.target.rawValue) || isForced
        if !depthOK { continue }

        if cut.omitZerosBeyondLevel1 && lvl > 1 && shown == 0 && !isForced { continue }

        rows.append((id, key, lvl, shown))
    }

    rows.sort { RGSNodeSortingCode(key: $0.key) < RGSNodeSortingCode(key: $1.key) } // uses your comparator. :contentReference[oaicite:3]{index=3}

    return rows.map { (id, key, lvl, amt) in
        let parentKey = key.split(separator: ".").dropLast().joined(separator: ".")
        let label =
            roll.nameById[id]           // node’s own short label (best)
            ?? labels[key]              // prefix table
            ?? labels[parentKey]
            ?? key
        return RGSPresentationLine(label: label, amount: amt, id: id, level: lvl)
    }
}
