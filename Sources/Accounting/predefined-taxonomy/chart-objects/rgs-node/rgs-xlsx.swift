import Foundation

public struct RGSNodeXLSXConcept: Sendable, Codable {
    public let sorting: RGSNodeSortingCode              // Excel sort path
    public let cachedSortingKey: String                   // cached text key
    public let links: RGSNodeLinksXLSXSortingKey
    public let filters: RGSNodeFilters?             // Excel applicability
    public let reference: String?                   // whatever the sheet exposed, legacy object
}
