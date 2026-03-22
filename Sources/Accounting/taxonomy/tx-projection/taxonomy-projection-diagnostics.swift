import Foundation

public struct TaxonomyProjectionDiagnostics: Sendable {
    public let selectedPresentations: [String]

    public let rankedGenericMappingCandidates: [String]
    public let selectedGenericMappingEntrypointPath: String?
    public let mappingEntryPaths: [String]
    public let mappingDiagnostics: [String: TaxonomyMappingResolutionDiagnostics]

    public let nonZeroNativeBalances: [(code: String, amount: Decimal)]
    public let resolvedMappings: [TaxonomyResolvedMapping]
    public let canonicalMappings: [TaxonomyCanonicalResolvedMapping]

    public let unmatchedRGSCodes: [(code: String, amount: Decimal)]

    public let computedFactsByKeyCount: Int
    public let computedConceptTotals: [String: Decimal]

    public let computedButNotRenderedConcepts: [String]
    public let renderedWithoutComputedFacts: [String]

    public let duplicateSourceExpansions: [TaxonomySourceExpansion]

    public init(
        selectedPresentations: [String],
        rankedGenericMappingCandidates: [String],
        selectedGenericMappingEntrypointPath: String?,
        mappingEntryPaths: [String],
        mappingDiagnostics: [String: TaxonomyMappingResolutionDiagnostics],
        nonZeroNativeBalances: [(code: String, amount: Decimal)],
        resolvedMappings: [TaxonomyResolvedMapping],
        canonicalMappings: [TaxonomyCanonicalResolvedMapping],
        unmatchedRGSCodes: [(code: String, amount: Decimal)],
        computedFactsByKeyCount: Int,
        computedConceptTotals: [String: Decimal],
        computedButNotRenderedConcepts: [String],
        renderedWithoutComputedFacts: [String],
        duplicateSourceExpansions: [TaxonomySourceExpansion]
    ) {
        self.selectedPresentations = selectedPresentations
        self.rankedGenericMappingCandidates = rankedGenericMappingCandidates
        self.selectedGenericMappingEntrypointPath = selectedGenericMappingEntrypointPath
        self.mappingEntryPaths = mappingEntryPaths
        self.mappingDiagnostics = mappingDiagnostics
        self.nonZeroNativeBalances = nonZeroNativeBalances
        self.resolvedMappings = resolvedMappings
        self.canonicalMappings = canonicalMappings
        self.unmatchedRGSCodes = unmatchedRGSCodes
        self.computedFactsByKeyCount = computedFactsByKeyCount
        self.computedConceptTotals = computedConceptTotals
        self.computedButNotRenderedConcepts = computedButNotRenderedConcepts
        self.renderedWithoutComputedFacts = renderedWithoutComputedFacts
        self.duplicateSourceExpansions = duplicateSourceExpansions
    }
}

public struct TaxonomySourceExpansion: Sendable, Hashable {
    public let sourceIdentifier: String
    public let targets: [String]

    public init(
        sourceIdentifier: String,
        targets: [String]
    ) {
        self.sourceIdentifier = sourceIdentifier
        self.targets = targets
    }
}
