import Foundation

public struct StatementCellDTO: Codable, Sendable {
    public let row: String
    public let partition: [String:String]   // pretty-printed dimension key/value
    public let periodIndex: Int             // 0=now, 1=previous …
    public let amount: Decimal
}

public struct StatementSnapshotDTO: Codable, Sendable {
    public let statementName: String
    public let kind: StatementKind
    public let cells: [StatementCellDTO]
}

@inline(__always)
private func prettyDim(_ k: DimensionKey, _ v: DimensionValue) -> (String,String) {
    switch v {
    case .text(let s): return (k.rawValue, s)
    case .entity(let e): return (k.rawValue, e.identifier(displaying: .fullchain))
    }
}

public func snapshotDTO(
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
