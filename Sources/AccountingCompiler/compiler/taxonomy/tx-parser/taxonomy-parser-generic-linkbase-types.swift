import Accounting
import Foundation

public struct TaxonomyRoleRef: Sendable, Hashable {
    public let roleURI: String
    public let href: String

    public init(
        roleURI: String,
        href: String
    ) {
        self.roleURI = roleURI
        self.href = href
    }
}

public struct TaxonomyArcroleRef: Sendable, Hashable {
    public let arcroleURI: String
    public let href: String

    public init(
        arcroleURI: String,
        href: String
    ) {
        self.arcroleURI = arcroleURI
        self.href = href
    }
}

public struct TaxonomyLocator: Sendable, Hashable {
    public let label: String
    public let href: String

    public init(
        label: String,
        href: String
    ) {
        self.label = label
        self.href = href
    }
}

public struct TaxonomyGenericResource: Sendable, Hashable {
    public let elementName: String
    public let label: String
    public let role: String?
    public let text: String
    public let attributes: [String: String]

    public init(
        elementName: String,
        label: String,
        role: String?,
        text: String,
        attributes: [String: String] = [:]
    ) {
        self.elementName = elementName
        self.label = label
        self.role = role
        self.text = text
        self.attributes = attributes
    }
}

public struct TaxonomyGenericArc: Sendable, Hashable {
    public let arcrole: String?
    public let from: String
    public let to: String
    public let order: Decimal?
    public let targetRole: String?
    public let attributes: [String: String]

    public init(
        arcrole: String?,
        from: String,
        to: String,
        order: Decimal? = nil,
        targetRole: String? = nil,
        attributes: [String: String] = [:]
    ) {
        self.arcrole = arcrole
        self.from = from
        self.to = to
        self.order = order
        self.targetRole = targetRole
        self.attributes = attributes
    }
}

public struct TaxonomyGenericExtendedLink: Sendable, Hashable {
    public let role: String?
    public let type: String
    public let locators: [String: TaxonomyLocator]
    public let resources: [String: TaxonomyGenericResource]
    public let arcs: [TaxonomyGenericArc]

    public init(
        role: String?,
        type: String,
        locators: [String: TaxonomyLocator] = [:],
        resources: [String: TaxonomyGenericResource] = [:],
        arcs: [TaxonomyGenericArc] = []
    ) {
        self.role = role
        self.type = type
        self.locators = locators
        self.resources = resources
        self.arcs = arcs
    }
}

public struct TaxonomyGenericLinkbase: Sendable {
    public let roleRefs: [TaxonomyRoleRef]
    public let arcroleRefs: [TaxonomyArcroleRef]
    public let links: [TaxonomyGenericExtendedLink]

    public init(
        roleRefs: [TaxonomyRoleRef] = [],
        arcroleRefs: [TaxonomyArcroleRef] = [],
        links: [TaxonomyGenericExtendedLink] = []
    ) {
        self.roleRefs = roleRefs
        self.arcroleRefs = arcroleRefs
        self.links = links
    }
}

public struct TaxonomyExplicitDimension: Sendable, Hashable {
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

public struct TaxonomyDatapoint: Sendable, Hashable {
    public let label: String
    public let primaryQName: String?
    public let dimensions: [TaxonomyExplicitDimension]

    public init(
        label: String,
        primaryQName: String?,
        dimensions: [TaxonomyExplicitDimension] = []
    ) {
        self.label = label
        self.primaryQName = primaryQName
        self.dimensions = dimensions
    }
}

