import Foundation

public struct TaxonomyRenderOptions: Sendable {
    public enum DefaultView: String, Sendable {
        case presentation
        case flattened
        case dimensional
    }

    public var defaultView: DefaultView
    public var pruneEmptyPresentationBranches: Bool
    public var showResolvedMappings: Bool
    public var showCanonicalMappings: Bool
    public var showComputedMappedFacts: Bool
    public var showCoverage: Bool
    public var showDimensionalPresentation: Bool
    public var comparePrevious: Bool

    public init(
        defaultView: DefaultView = .presentation,
        pruneEmptyPresentationBranches: Bool = true,
        showResolvedMappings: Bool = false,
        showCanonicalMappings: Bool = false,
        showComputedMappedFacts: Bool = false,
        showCoverage: Bool = false,
        showDimensionalPresentation: Bool = false,
        comparePrevious: Bool = false
    ) {
        self.defaultView = defaultView
        self.pruneEmptyPresentationBranches = pruneEmptyPresentationBranches
        self.showResolvedMappings = showResolvedMappings
        self.showCanonicalMappings = showCanonicalMappings
        self.showComputedMappedFacts = showComputedMappedFacts
        self.showCoverage = showCoverage
        self.showDimensionalPresentation = showDimensionalPresentation
        self.comparePrevious = comparePrevious
    }
}
