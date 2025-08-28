import Foundation

public struct StatementCellKey: Hashable, Codable, Sendable { 
    public let row: StatementRowId
    public let partition: [DimensionKey: DimensionValue] // ordered by keys for stable hashing
    public let periodIndex: Int                          // 0=this period, 1=prev, …
}

public typealias StatementCube = [StatementCellKey: Decimal]

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
