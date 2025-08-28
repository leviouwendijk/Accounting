import Foundation

// // Compare "A.B.A010" segments: alpha prefix lexicographically, numeric tail numerically
// public func sortKeyLess(_ a: String, _ b: String) -> Bool {
//     func splitSeg(_ s: Substring) -> (String, Int?) {
//         let str = String(s)
//         let letters = str.prefix { $0.isLetter }
//         let digits  = str.suffix { $0.isNumber }
//         return (String(letters), Int(digits))
//     }
//     let asg = a.split(separator: ".")
//     let bsg = b.split(separator: ".")
//     for i in 0..<min(asg.count, bsg.count) {
//         let (al, an) = splitSeg(asg[i])
//         let (bl, bn) = splitSeg(bsg[i])
//         if al != bl { return al < bl }
//         if an != bn { return (an ?? -1) < (bn ?? -1) }
//     }
//     return asg.count < bsg.count
// }

public struct RGSPresentationLine {
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
    target: TargetLevel,
    omslag: OmslagMode
) -> [RGSPresentationLine] {
    // collect ids of desired statement kind & within level cutoff
    var rows: [(id:Int, key:String, lvl:Int, amt:Decimal)] = []
    for (id, key) in roll.sortKeyById {
        guard roll.kindById[id] == kind else { continue }
        let lvl = key.isEmpty ? 1 : key.split(separator: ".").count
        guard lvl <= target.rawValue else { continue }
        let raw = totals[id] ?? 0
        let shown = RGSAssembler.present(raw, direction: roll.directionById[id] ?? .debit, mode: omslag)
        rows.append((id, key, lvl, shown))
    }

    rows.sort { 
        RGSNodeSortingCode(key: $0.key) < RGSNodeSortingCode(key: $1.key)
    }

    return rows.map { (id, key, lvl, amt) in
        let label = labels[key] ?? labels[key.split(separator: ".").dropLast().joined(separator: ".")] ?? "—"
        return RGSPresentationLine(label: label, amount: amt, id: id, level: lvl)
    }
}
