import Foundation

public enum DimensionKey: String, Codable, Sendable, Hashable {
    case entity          // full EntityKey (class+family+alias)
    case entityClass     // e.g., "people" | "objects" | "liquids"
    case entityFamily    // e.g., "storable" | "usable" | …
    case entityAlias     // e.g., "macbook#levi_air_m2"
    // future: case project, location, department, counterparty, …
}

public enum DimensionValue: Codable, Sendable, Hashable {
    case text(String)
    case entity(EntityKey)
}

public typealias DimensionSlice = [DimensionKey: DimensionValue]

public struct DimensionFilter: Codable, Sendable {
    public enum Op: String, Codable, Sendable { 
        case equals, `in`, notEquals, notIn 
    }

    public let key: DimensionKey
    public let op: Op
    public let values: [DimensionValue]
    
    public init(
        key: DimensionKey,
        op: Op,
        values: [DimensionValue]
    ) {
        self.key = key
        self.op = op
        self.values = values
    }
}
