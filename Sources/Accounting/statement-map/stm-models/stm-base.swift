import Foundation

public struct StatementRowId: Hashable, Codable, Sendable { 
    public let raw: String
}

public struct RGSMappingRule: Codable, Sendable {
    public var includeCodes: [String]?       // exact
    public var includePrefixes: [String]?    // hierarchy family
    public var includeLevel: Int?            // optional level constraint
    public var filterDirection: Direction?   // optional: match account natural side
}

public struct StatementRowDef: Codable, Sendable {
    public let id: StatementRowId
    public let label: String
    public let kind: StatementKind
    public let materialityThreshold: Decimal?
    public let rgs: [RGSMappingRule]
}

public struct StatementDef: Codable, Sendable {
    public let name: String
    public let kind: StatementKind
    public let rows: [StatementRowDef]
}
