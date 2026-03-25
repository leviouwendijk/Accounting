import Foundation

public struct RGSNodeXLSXConcept: Sendable, Codable {
    public let sorting: RGSNodeSortingCode              
    public let cachedSortingKey: String                   
    public let links: RGSNodeLinksXLSXSortingKey
    public let filters: RGSNodeFilters?             
    public let reference: String?                   
    
    public init(
        sortingKey: String,
        links: RGSNodeLinksXLSXSortingKey,
        filters: RGSNodeFilters?,
        reference: String?
    ) {
        self.sorting = RGSNodeSortingCode(key: sortingKey)
        self.cachedSortingKey = sorting.key
        self.links = links
        self.filters = filters
        self.reference = reference
    }

    public init(
        sortingCode: RGSNodeSortingCode,
        links: RGSNodeLinksXLSXSortingKey,
        filters: RGSNodeFilters?,
        reference: String?
    ) {
        self.sorting = sortingCode
        self.cachedSortingKey = sorting.key
        self.links = links
        self.filters = filters
        self.reference = reference
    }
}


// public struct RGSNodeXLSXConcept: Sendable, Codable {
//     public let sorting: RGSNodeSortingCode              // Excel sort path
//     public let cachedSortingKey: String                   // cached text key
//     public let links: RGSNodeLinksXLSXSortingKey
//     public let filters: RGSNodeFilters?             // Excel applicability
//     public let reference: String?                   // whatever the sheet exposed, legacy object
// }
