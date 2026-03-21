import Foundation

public struct TaxonomyResolvedMapping: Sendable, Hashable {
    public let sourceIdentifier: String
    public let matchedCode: String?
    public let targetConcept: String
    public let dimensions: [TaxonomyExplicitDimension]

    public init(
        sourceIdentifier: String,
        matchedCode: String?,
        targetConcept: String,
        dimensions: [TaxonomyExplicitDimension] = []
    ) {
        self.sourceIdentifier = sourceIdentifier
        self.matchedCode = matchedCode
        self.targetConcept = targetConcept
        self.dimensions = dimensions
    }
}

public struct TaxonomyConceptNameExtraction: Sendable, Hashable {
    public let localName: String
    public let normalizedName: String

    public init(
        localName: String,
        normalizedName: String
    ) {
        self.localName = localName
        self.normalizedName = normalizedName
    }
}

public struct TaxonomyMappingResolutionDiagnostics: Sendable {
    public let totalDatapoints: Int
    public let resolvedCount: Int
    public let unresolvedCount: Int
    public let unresolvedConceptSamples: [String]

    public init(
        totalDatapoints: Int,
        resolvedCount: Int,
        unresolvedCount: Int,
        unresolvedConceptSamples: [String] = []
    ) {
        self.totalDatapoints = totalDatapoints
        self.resolvedCount = resolvedCount
        self.unresolvedCount = unresolvedCount
        self.unresolvedConceptSamples = unresolvedConceptSamples
    }
}

public struct TaxonomyMappingResolutionResult: Sendable {
    public let resolvedMappings: [TaxonomyResolvedMapping]
    public let diagnostics: TaxonomyMappingResolutionDiagnostics

    public init(
        resolvedMappings: [TaxonomyResolvedMapping],
        diagnostics: TaxonomyMappingResolutionDiagnostics
    ) {
        self.resolvedMappings = resolvedMappings
        self.diagnostics = diagnostics
    }
}
