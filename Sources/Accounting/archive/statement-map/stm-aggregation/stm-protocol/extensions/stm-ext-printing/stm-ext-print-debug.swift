import Foundation

public extension StatementAggregating {
    func dumpCube(_ tag: String, _ cube: StatementCube) {
        FileHandle.standardError.write(Data(("\n[TRACE] \(tag)\n").utf8))
        for (k, v) in cube.sorted(by: { $0.key.row.raw < $1.key.row.raw }) {
            let part = k.partition.map { "\($0.key.rawValue)=\($0.value)" }.sorted().joined(separator: ",")
            let line = "  \(k.row.raw){p\(k.periodIndex)} [\(part)]: \(v)\n"
            FileHandle.standardError.write(Data(line.utf8))
        }
    }

    func snapshotDTO(
        cube: StatementCube,
        statement: StatementDef
    ) -> StatementSnapshotDTO {
        let cells: [StatementCellDTO] = cube.map { (key, amt) in
            let dimPairs = key.partition.map { prettyDim($0.key, $0.value) }
            let dict = Dictionary(uniqueKeysWithValues: dimPairs)
            return StatementCellDTO(
                row: key.row.raw,
                partition: dict,
                periodIndex: key.periodIndex,
                amount: amt
            )
        }
        .sorted { (a, b) in
            if a.row != b.row { return a.row < b.row }
            if a.periodIndex != b.periodIndex { return a.periodIndex < b.periodIndex }
            return a.partition.description < b.partition.description
        }

        return .init(statementName: statement.name, kind: statement.kind, cells: cells)
    }
}
