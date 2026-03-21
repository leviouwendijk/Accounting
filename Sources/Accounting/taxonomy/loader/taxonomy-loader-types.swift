import Foundation

public struct LoadedTaxonomy: Sendable {
    public let source: TaxonomySourceData
    public let entrypointURL: URL
    public let entrypointBasename: String
    public let refs: TaxonomyEntrypointRefs

    public let selectedPresentationURLs: [URL]
    public let selectedPresentationLinks: [TaxonomyPresentationLink]
    public let allPresentationLinksByURL: [String: [TaxonomyPresentationLink]]

    public let labelsByConcept: [String: String]

    public init(
        source: TaxonomySourceData,
        entrypointURL: URL,
        entrypointBasename: String,
        refs: TaxonomyEntrypointRefs,
        selectedPresentationURLs: [URL],
        selectedPresentationLinks: [TaxonomyPresentationLink],
        allPresentationLinksByURL: [String: [TaxonomyPresentationLink]],
        labelsByConcept: [String: String]
    ) {
        self.source = source
        self.entrypointURL = entrypointURL
        self.entrypointBasename = entrypointBasename
        self.refs = refs
        self.selectedPresentationURLs = selectedPresentationURLs
        self.selectedPresentationLinks = selectedPresentationLinks
        self.allPresentationLinksByURL = allPresentationLinksByURL
        self.labelsByConcept = labelsByConcept
    }
}

public struct TaxonomyLoadConfig: Sendable {
    public let source: TaxonomySourceData
    public let wantedPresentations: [String]
    public let labelHrefs: [String]

    public init(
        source: TaxonomySourceData,
        wantedPresentations: [String]? = nil,
        labelHrefs: [String]? = nil
    ) {
        self.source = source
        self.wantedPresentations = wantedPresentations ?? source.wantedPresentations
        self.labelHrefs = labelHrefs ?? source.labelHrefs
    }
}
