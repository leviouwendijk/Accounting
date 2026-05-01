import Accounting
import Foundation

// new type for node reducer:
public struct TaxonomyNormalizedResolvedMapping: Sendable {
    public let targetConcept: String
    public let dimensions: [TaxonomyExplicitDimension]
    public let sourceNodeId: Int
    public let sourceCode: String

    public init(
        targetConcept: String,
        dimensions: [TaxonomyExplicitDimension],
        sourceNodeId: Int,
        sourceCode: String
    ) {
        self.targetConcept = targetConcept
        self.dimensions = dimensions
        self.sourceNodeId = sourceNodeId
        self.sourceCode = sourceCode
    }
}

public struct TaxonomyResolvedMapping: Sendable, Hashable {
    public let sourceHref: String
    public let sourceLocatorLabel: String
    public let sourceIdentifier: String
    public let matchedCode: String?

    public let targetDatapointLabel: String
    public let targetPrimaryQName: String
    public let targetConcept: String

    public let dimensions: [TaxonomyExplicitDimension]
    public let arcOrder: Decimal?

    public init(
        sourceHref: String,
        sourceLocatorLabel: String,
        sourceIdentifier: String,
        matchedCode: String?,
        targetDatapointLabel: String,
        targetPrimaryQName: String,
        targetConcept: String,
        dimensions: [TaxonomyExplicitDimension] = [],
        arcOrder: Decimal? = nil
    ) {
        self.sourceHref = sourceHref
        self.sourceLocatorLabel = sourceLocatorLabel
        self.sourceIdentifier = sourceIdentifier
        self.matchedCode = matchedCode
        self.targetDatapointLabel = targetDatapointLabel
        self.targetPrimaryQName = targetPrimaryQName
        self.targetConcept = targetConcept
        self.dimensions = dimensions
        self.arcOrder = arcOrder
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
