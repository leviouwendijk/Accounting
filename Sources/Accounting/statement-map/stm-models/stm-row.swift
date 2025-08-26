import Foundation

public struct RowPeriodKey: Hashable {
    public let row: StatementRowId
    public let period: Int
}

public struct RowMatcher {
    public let row: StatementRowDef
    public let predicate: (NormalizedPosting) -> Bool
}

public enum StatementRowIds: Sendable { 
    public static let balancing = StatementRowId(raw: "__balancing__") 
    public static let other = StatementRowId(raw: "__other__") 
}
