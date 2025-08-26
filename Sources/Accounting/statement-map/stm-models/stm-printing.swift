import Foundation

@inline(__always)
public func fmt(_ d: Decimal) -> String {
    // change to your formatter if you prefer
    var v = d
    return NSDecimalString(&v, Locale(identifier: "nl_NL"))
}

public func label(for part: [DimensionKey: DimensionValue]) -> String {
    if part.isEmpty { return "(total)" }
    var chunks: [String] = []
    // stable order
    for k in part.keys.sorted(by: { $0.rawValue < $1.rawValue }) {
        guard let v = part[k] else { continue }
        switch v {
        case .text(let s):
            chunks.append("\(k.rawValue)=\(s)")
        case .entity(let e):
            chunks.append("\(k.rawValue)=\(e.identifier(displaying: .fullchain))")
        }
    }
    if chunks.isEmpty { return "(total)" }
    return chunks.joined(separator: ", ")
}

/// prints a simple table for periodIndex 0 (current period).
/// if you also built previous-period cubes, you can add an extra column similarly.
public func printStatement(_ title: String, cube: StatementCube, statement: StatementDef, periodIndex: Int = 0) {
    FileHandle.standardError.write(Data(("\n\(title)\n" + String(repeating: "—", count: title.count) + "\n").utf8))

    var grandTotal: Decimal = 0

    // iterate rows in the order defined by the statement
    for row in statement.rows {
        // gather all partitions for this row/period
        let rowCells = cube.filter { $0.key.row == row.id && $0.key.periodIndex == periodIndex }
        guard !rowCells.isEmpty else { continue }

        FileHandle.standardError.write(Data(("\n\(row.label):\n").utf8))

        // sort partitions for stable output
        let sorted = rowCells.sorted { a, b in
            let la = label(for: a.key.partition)
            let lb = label(for: b.key.partition)
            return la < lb
        }

        var rowTotal: Decimal = 0
        for (k, amt) in sorted {
            let line = "  • \(label(for: k.partition))  \(fmt(amt))\n"
            FileHandle.standardError.write(Data(line.utf8))
            rowTotal += amt
        }
        grandTotal += rowTotal
        let totalLine = "  = \(row.label) total: \(fmt(rowTotal))\n"
        FileHandle.standardError.write(Data(totalLine.utf8))
    }

    FileHandle.standardError.write(Data(("—\nGrand total: \(fmt(grandTotal))\n\n").utf8))
}
