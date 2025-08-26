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
    var printedRows = Set<StatementRowId>()

    // iterate rows in the order defined by the statement
    for row in statement.rows {
        printedRows.insert(row.id)
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

    // 2) print balancing row if present
    let balCells = cube.filter { $0.key.row == BALANCING_ROW_ID && $0.key.periodIndex == periodIndex }
    if !balCells.isEmpty {
        FileHandle.standardError.write(Data(("\nBalancing:\n").utf8))
        var rowTotal: Decimal = 0
        for (k, amt) in balCells.sorted(by: { label(for: $0.key.partition) < label(for: $1.key.partition) }) {
            let line = "  • \(label(for: k.partition))  \(fmt(amt))\n"
            FileHandle.standardError.write(Data(line.utf8))
            rowTotal += amt
        }
        grandTotal += rowTotal
        FileHandle.standardError.write(Data(("  = Balancing total: \(fmt(rowTotal))\n").utf8))
    }

    // 3) footer
    FileHandle.standardError.write(Data(("—\nGrand total: \(fmt(grandTotal))\n\n").utf8))
}

public func totalsForBalance(cube: StatementCube, statement: StatementDef, periodIndex: Int) -> (assets: Decimal, liab: Decimal, eq: Decimal) {
    func sumRow(_ idRaw: String) -> Decimal {
        let id = StatementRowId(raw: idRaw)
        return cube.reduce(0) { partial, kv in
            kv.key.periodIndex == periodIndex && kv.key.row == id ? partial + kv.value : partial
        }
    }
    let assets = sumRow("assets")
    let liab   = sumRow("liabilities")
    let eq     = sumRow("equity")
    return (assets, liab, eq)
}

public func printBalanceCheck(cube: StatementCube, statement: StatementDef, periodIndex: Int = 0) {
    // Assets (debit-natured) shown as +; Liab & Equity (credit-natured) shown as +
    let assets =  sumRow(cube, "assets", periodIndex)                  // debit -> show as-is
    let liab   = -sumRow(cube, "liabilities", periodIndex)             // credit -> flip sign
    let equity = -sumRow(cube, "equity", periodIndex)                  // credit -> flip sign

    let rhs  = liab + equity
    let diff = assets - rhs

    FileHandle.standardError.write(Data(
        ("Check: Assets (\(fmt(assets))) vs Liab+Equity (\(fmt(rhs))) → Diff \(fmt(diff))\n").utf8
    ))
}

public func dumpCube(_ tag: String, _ cube: StatementCube) {
    FileHandle.standardError.write(Data(("\n[TRACE] \(tag)\n").utf8))
    for (k, v) in cube.sorted(by: { $0.key.row.raw < $1.key.row.raw }) {
        let part = k.partition.map { "\($0.key.rawValue)=\($0.value)" }.sorted().joined(separator: ",")
        let line = "  \(k.row.raw){p\(k.periodIndex)} [\(part)]: \(v)\n"
        FileHandle.standardError.write(Data(line.utf8))
    }
}
