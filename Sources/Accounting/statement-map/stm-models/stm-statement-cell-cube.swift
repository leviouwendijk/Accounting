import Foundation

public struct StatementCellKey: Hashable { 
    public let row: StatementRowId
    public let partition: [DimensionKey: DimensionValue] // ordered by keys for stable hashing
    public let periodIndex: Int                          // 0=this period, 1=prev, …
}
public typealias StatementCube = [StatementCellKey: Decimal]
