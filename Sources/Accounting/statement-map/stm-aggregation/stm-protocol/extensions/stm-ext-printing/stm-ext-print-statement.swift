import Foundation

public extension StatementAggregating {
    /// prints a simple table for periodIndex 0 (current period).
    /// if you also built previous-period cubes, you can add an extra column similarly.
    func printStatement(_ title: String, cube: StatementCube, statement: StatementDef, periodIndex: Int = 0) {
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
        let balCells = cube.filter { $0.key.row == StatementRowIds.balancing && $0.key.periodIndex == periodIndex }
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
}
