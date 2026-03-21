import Foundation

public struct TaxonomyLinkbaseRef: Sendable, Hashable {
    public let href: String
    public let role: String?

    public init(
        href: String,
        role: String?
    ) {
        self.href = href
        self.role = role
    }
}

public struct TaxonomyEntrypointRefs: Sendable {
    public let presentation: [TaxonomyLinkbaseRef]
    public let labels: [TaxonomyLinkbaseRef]
    public let definitions: [TaxonomyLinkbaseRef]
    public let tables: [TaxonomyLinkbaseRef]
    public let mappings: [TaxonomyLinkbaseRef]
    public let other: [TaxonomyLinkbaseRef]

    public init(
        presentation: [TaxonomyLinkbaseRef] = [],
        labels: [TaxonomyLinkbaseRef] = [],
        definitions: [TaxonomyLinkbaseRef] = [],
        tables: [TaxonomyLinkbaseRef] = [],
        mappings: [TaxonomyLinkbaseRef] = [],
        other: [TaxonomyLinkbaseRef] = []
    ) {
        self.presentation = presentation
        self.labels = labels
        self.definitions = definitions
        self.tables = tables
        self.mappings = mappings
        self.other = other
    }
}
