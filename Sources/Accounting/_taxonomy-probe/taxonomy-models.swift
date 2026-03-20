import Foundation

public struct GenericLinkbase: Sendable {
    public let roleRefs: [RoleRef]
    public let arcroleRefs: [ArcroleRef]
    public let links: [GenericExtendedLink]
}

public struct RoleRef: Sendable {
    public let roleURI: String
    public let href: String
}

public struct ArcroleRef: Sendable {
    public let arcroleURI: String
    public let href: String
}

public struct GenericExtendedLink: Sendable {
    public let role: String
    public let locators: [String: Locator]
    public let resources: [String: GenericResource]
    public let arcs: [GenericArc]
}

public struct Locator: Sendable {
    public let label: String
    public let href: String
}

public struct GenericResource: Sendable {
    public let elementName: String
    public let label: String?
    public let role: String?
    public let attributes: [String: String]
    public let text: String
}

public struct GenericArc: Sendable {
    public let elementName: String
    public let arcrole: String?
    public let from: String
    public let to: String
    public let order: Double?
    public let attributes: [String: String]
}

public struct RGSExplicitDimension: Sendable {
    public let qname: String
    public let member: String?
}

public struct RGSDatapoint: Sendable {
    public let label: String
    public let id: String?
    public let role: String?
    public let primaryQName: String?
    public let dimensions: [RGSExplicitDimension]
}

public struct ResolvedMapping: Sendable {
    public let sourceLocatorLabel: String
    public let sourceHref: String
    public let sourceConcept: String
    public let targetDatapointLabel: String
    public let targetPrimaryQName: String
    public let dimensions: [RGSExplicitDimension]
    public let order: Double?
}

public struct CanonicalResolvedMapping: Sendable {
    public let sourceLocatorLabel: String
    public let sourceHref: String
    public let sourceConcept: String
    public let sourceIdentifier: String
    public let sourceCode: String
    public let targetDatapointLabel: String
    public let targetPrimaryQName: String
    public let dimensions: [RGSExplicitDimension]
    public let order: Double?
}

// additions:
public struct DimensionBinding: Hashable, Sendable {
    public let qname: String
    public let member: String?
}

public struct MappedFactKey: Hashable, Sendable {
    public let concept: String
    public let dimensions: [DimensionBinding]
}

public struct ComputedMappedFact: Sendable {
    public let key: MappedFactKey
    public let amount: Decimal
    public let matchedCodes: [String]
    public let contributingMappings: [CanonicalResolvedMapping]
}

// fuzzy
public struct MappingSuggestion: Sendable {
    public let queryCode: String
    public let candidateCode: String
    public let score: Int
    public let reasons: [String]
}

// new mapping diag
public struct ConceptNameExtraction: Sendable {
    public enum Method: String, Sendable {
        case urlFragment
        case rawHashFragment
        case fallbackWholeHref
        case emptyHref
    }

    public let href: String
    public let concept: String?
    public let method: Method
}

public struct MappingResolutionDiagnostics: Sendable {
    public var totalArcs: Int = 0
    public var resolvedMappings: Int = 0
    public var droppedMissingLocator: Int = 0
    public var droppedMissingDatapoint: Int = 0
    public var droppedMissingPrimaryQName: Int = 0
    public var droppedMissingSourceConcept: Int = 0
    public var sourceConceptFromURLFragment: Int = 0
    public var sourceConceptFromRawHashFragment: Int = 0
    public var sourceConceptFromFallbackWholeHref: Int = 0
    public var sourceConceptFromEmptyHref: Int = 0
    public var arcroles: [String: Int] = [:]
    public var sampleMissingLocatorLabels: [String] = []
    public var sampleMissingDatapointLabels: [String] = []
    public var sampleMissingPrimaryQNameDatapoints: [String] = []
    public var sampleFallbackSourceHrefs: [String] = []

    public init() {}
}

public struct MappingResolutionResult: Sendable {
    public let mappings: [ResolvedMapping]
    public let diagnostics: MappingResolutionDiagnostics
}
