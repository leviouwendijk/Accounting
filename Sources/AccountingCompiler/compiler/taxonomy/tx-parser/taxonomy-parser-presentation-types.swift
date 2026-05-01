import Accounting
import Foundation

public struct TaxonomyPresentationArc: Sendable, Hashable {
    public let parent: String
    public let child: String
    public let order: Decimal?

    public init(
        parent: String,
        child: String,
        order: Decimal? = nil
    ) {
        self.parent = parent
        self.child = child
        self.order = order
    }
}

public struct TaxonomyPresentationLink: Sendable {
    public let role: String?
    public let locators: [String: String]
    public let arcs: [TaxonomyPresentationArc]

    public init(
        role: String?,
        locators: [String: String],
        arcs: [TaxonomyPresentationArc]
    ) {
        self.role = role
        self.locators = locators
        self.arcs = arcs
    }
}
