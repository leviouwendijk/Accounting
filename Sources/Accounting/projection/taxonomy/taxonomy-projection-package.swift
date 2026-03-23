import Foundation

public struct TaxonomyCompileProjectionOutput: Sendable {
    public let profile: String
    public let bootstrap: LoadedTaxonomy
    public let resolvedMappings: [TaxonomyResolvedMapping]
    public let canonicalMappings: [TaxonomyCanonicalResolvedMapping]

    public let balances: [String: Decimal]

    public let factsByKey: [TaxonomyMappedFactKey: TaxonomyComputedMappedFact]
    public let factsByConcept: [String: [TaxonomyComputedMappedFact]]
    public let flattenedFacts: [String: TaxonomyComputedFact]

    public let diagnostics: TaxonomyProjectionDiagnostics?

    public init(
        profile: String,
        bootstrap: LoadedTaxonomy,
        resolvedMappings: [TaxonomyResolvedMapping],
        canonicalMappings: [TaxonomyCanonicalResolvedMapping],
        balances: [String: Decimal],
        factsByKey: [TaxonomyMappedFactKey: TaxonomyComputedMappedFact],
        factsByConcept: [String: [TaxonomyComputedMappedFact]],
        flattenedFacts: [String: TaxonomyComputedFact],
        diagnostics: TaxonomyProjectionDiagnostics? = nil
    ) {
        self.profile = profile
        self.bootstrap = bootstrap
        self.resolvedMappings = resolvedMappings
        self.canonicalMappings = canonicalMappings
        self.balances = balances
        self.factsByKey = factsByKey
        self.factsByConcept = factsByConcept
        self.flattenedFacts = flattenedFacts
        self.diagnostics = diagnostics
    }
}

public struct TaxonomyPeriodProjectionOutput: Sendable {
    public let profile: String
    public let bootstrap: LoadedTaxonomy
    public let resolvedMappings: [TaxonomyResolvedMapping]
    public let canonicalMappings: [TaxonomyCanonicalResolvedMapping]

    public let currentBalances: [String: Decimal]
    public let currentFactsByKey: [TaxonomyMappedFactKey: TaxonomyComputedMappedFact]
    public let currentFactsByConcept: [String: [TaxonomyComputedMappedFact]]
    public let currentFlattenedFacts: [String: TaxonomyComputedFact]

    public let previousBalances: [String: Decimal]?
    public let previousFactsByKey: [TaxonomyMappedFactKey: TaxonomyComputedMappedFact]?
    public let previousFactsByConcept: [String: [TaxonomyComputedMappedFact]]?
    public let previousFlattenedFacts: [String: TaxonomyComputedFact]?

    public let currentRange: PeriodWindow
    public let previousRange: PeriodWindow?

    public let diagnostics: TaxonomyProjectionDiagnostics?

    public init(
        profile: String,
        bootstrap: LoadedTaxonomy,
        resolvedMappings: [TaxonomyResolvedMapping],
        canonicalMappings: [TaxonomyCanonicalResolvedMapping],
        currentBalances: [String: Decimal],
        currentFactsByKey: [TaxonomyMappedFactKey: TaxonomyComputedMappedFact],
        currentFactsByConcept: [String: [TaxonomyComputedMappedFact]],
        currentFlattenedFacts: [String: TaxonomyComputedFact],
        previousBalances: [String: Decimal]?,
        previousFactsByKey: [TaxonomyMappedFactKey: TaxonomyComputedMappedFact]?,
        previousFactsByConcept: [String: [TaxonomyComputedMappedFact]]?,
        previousFlattenedFacts: [String: TaxonomyComputedFact]?,
        currentRange: PeriodWindow,
        previousRange: PeriodWindow?,
        diagnostics: TaxonomyProjectionDiagnostics? = nil
    ) {
        self.profile = profile
        self.bootstrap = bootstrap
        self.resolvedMappings = resolvedMappings
        self.canonicalMappings = canonicalMappings
        self.currentBalances = currentBalances
        self.currentFactsByKey = currentFactsByKey
        self.currentFactsByConcept = currentFactsByConcept
        self.currentFlattenedFacts = currentFlattenedFacts
        self.previousBalances = previousBalances
        self.previousFactsByKey = previousFactsByKey
        self.previousFactsByConcept = previousFactsByConcept
        self.previousFlattenedFacts = previousFlattenedFacts
        self.currentRange = currentRange
        self.previousRange = previousRange
        self.diagnostics = diagnostics
    }
}

