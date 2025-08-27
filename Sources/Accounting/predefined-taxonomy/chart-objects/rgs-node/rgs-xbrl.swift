import Foundation

public struct RGSNodeXBRLConcept: Sendable, Codable, Hashable {
    public let concept: RGSXBRLConceptMetadata          
    public let presentations: [RGSNodeLinksPresentationBase] 
    
    public init(
        concept: RGSXBRLConceptMetadata,
        presentations: [RGSNodeLinksPresentationBase]
    ) {
        self.concept = concept
        self.presentations = presentations
    }

    public var postable: Bool {
        !concept.abstract && (concept.dataType.contains("monetaryItemType"))
    }
}

public struct RGSXBRLConceptMetadata: Hashable, Codable, Sendable {
    public let abstract: Bool
    public let namespace: RGSNameSpace
    public let dataType: String
    public let documentation: String?
    
    public init(
        abstract: Bool,
        namespace: RGSNameSpace,
        dataType: String,
        documentation: String?
    ) {
        self.abstract = abstract
        self.namespace = namespace
        self.dataType = dataType
        self.documentation = documentation
    }
}


// public struct RGSNodeXBRLConcept: Sendable, Codable, Hashable {
//     public let concept: RGSXBRLConceptMetadata          // abstract, namespace, type, periodType, balance, docs
//     public let presentations: [RGSNodeLinksPresentationBase] // (parentId, roleURI, order, preferredLabel)

//     public var postable: Bool {
//         !concept.abstract && (concept.dataType.contains("monetaryItemType"))
//     }
// }
