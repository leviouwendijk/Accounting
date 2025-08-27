import Foundation

public struct RGSNodeXLSXConcept: Sendable, Codable {
    public let sorting: RGSNodeSortingCode              
    public let cachedSortingKey: String                   
    public let links: RGSNodeLinksXLSXSortingKey
    public let filters: RGSNodeFilters?             
    public let reference: String?                   
    
    public init(
        sorting: RGSNodeSortingCode,
        cachedSortingKey: String,
        links: RGSNodeLinksXLSXSortingKey,
        filters: RGSNodeFilters?,
        reference: String?
    ) {
        self.sorting = sorting
        self.cachedSortingKey = cachedSortingKey
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
