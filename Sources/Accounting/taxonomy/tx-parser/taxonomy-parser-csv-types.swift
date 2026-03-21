import Foundation

public struct TaxonomyCSVMappingFile: Sendable {
    public let header: [String]
    public let rows: [TaxonomyCSVMappingRow]

    public init(
        header: [String],
        rows: [TaxonomyCSVMappingRow]
    ) {
        self.header = header
        self.rows = rows
    }
}

public struct TaxonomyCSVMappingRow: Sendable, Hashable {
    public let source: TaxonomyCSVMappingSource
    public let targetConcept: String
    public let dimensions: [TaxonomyExplicitDimension]
    public let raw: [String: String]

    public init(
        source: TaxonomyCSVMappingSource,
        targetConcept: String,
        dimensions: [TaxonomyExplicitDimension] = [],
        raw: [String: String] = [:]
    ) {
        self.source = source
        self.targetConcept = targetConcept
        self.dimensions = dimensions
        self.raw = raw
    }
}

public enum TaxonomyCSVMappingSource: Sendable, Hashable {
    case exact(String)
    case prefix(String)
    case glob(String)
    case group([TaxonomyCSVGroupTerm])
}

public struct TaxonomyCSVGroupTerm: Sendable, Hashable {
    public let sign: Decimal
    public let pattern: String

    public init(
        sign: Decimal,
        pattern: String
    ) {
        self.sign = sign
        self.pattern = pattern
    }
}
