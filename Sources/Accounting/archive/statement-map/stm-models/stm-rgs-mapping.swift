import Foundation

public struct RGSMappingRule: Codable, Sendable {
    public var includeCodes: [String]?       // exact
    public var includePrefixes: [String]?    // hierarchy family
    public var includeLevel: Int?            // optional level constraint
    public var includeOmslagPrefixes: [String]?    // ← new
    public var filterDirection: Direction?   // optional: match account natural side
    
    public init(
        includeCodes: [String]?,       
        includePrefixes: [String]?,    
        includeLevel: Int?,            
        includeOmslagPrefixes: [String]?,
        filterDirection: Direction?   
    ) {
        self.includeCodes = includeCodes
        self.includePrefixes = includePrefixes
        self.includeLevel = includeLevel
        self.includeOmslagPrefixes = includeOmslagPrefixes
        self.filterDirection = filterDirection
    }
}
