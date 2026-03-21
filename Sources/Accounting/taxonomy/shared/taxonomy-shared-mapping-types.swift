import Foundation

public struct TaxonomyAccountLookup: Sendable, Hashable {
    public let byIdentifier: [String: String]
    public let byCode: [String: String]

    public init(
        byIdentifier: [String: String],
        byCode: [String: String]
    ) {
        self.byIdentifier = byIdentifier
        self.byCode = byCode
    }
}

public struct TaxonomyCanonicalResolvedMapping: Sendable, Hashable {
    public let sourceIdentifier: String
    public let matchedCode: String
    public let targetConcept: String
    public let dimensions: [TaxonomyExplicitDimension]

    public init(
        sourceIdentifier: String,
        matchedCode: String,
        targetConcept: String,
        dimensions: [TaxonomyExplicitDimension] = []
    ) {
        self.sourceIdentifier = sourceIdentifier
        self.matchedCode = matchedCode
        self.targetConcept = targetConcept
        self.dimensions = dimensions
    }
}

public struct TaxonomyDimensionBinding: Sendable, Hashable {
    public let axis: String
    public let member: String

    public init(
        axis: String,
        member: String
    ) {
        self.axis = axis
        self.member = member
    }
}

public struct TaxonomyMappedFactKey: Sendable, Hashable {
    public let concept: String
    public let dimensions: [TaxonomyDimensionBinding]

    public init(
        concept: String,
        dimensions: [TaxonomyDimensionBinding] = []
    ) {
        self.concept = concept
        self.dimensions = dimensions
    }
}

public struct TaxonomyComputedMappedFact: Sendable, Hashable {
    public let concept: String
    public let amount: Decimal
    public let dimensions: [TaxonomyDimensionBinding]
    public let sourceCodes: [String]

    public init(
        concept: String,
        amount: Decimal,
        dimensions: [TaxonomyDimensionBinding] = [],
        sourceCodes: [String] = []
    ) {
        self.concept = concept
        self.amount = amount
        self.dimensions = dimensions
        self.sourceCodes = sourceCodes
    }
}

public struct TaxonomyComputedFact: Sendable, Hashable {
    public let concept: String
    public let amount: Decimal

    public init(
        concept: String,
        amount: Decimal
    ) {
        self.concept = concept
        self.amount = amount
    }
}

public struct TaxonomyMappingSuggestion: Sendable, Hashable {
    public let unmatchedCode: String
    public let suggestedCode: String
    public let score: Int
    public let targetConcepts: [String]

    public init(
        unmatchedCode: String,
        suggestedCode: String,
        score: Int,
        targetConcepts: [String] = []
    ) {
        self.unmatchedCode = unmatchedCode
        self.suggestedCode = suggestedCode
        self.score = score
        self.targetConcepts = targetConcepts
    }
}
