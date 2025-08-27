import Foundation

public struct RGSNameSpace: Hashable, Codable, Sendable { 
    public let space: String
    public let localization: String 
    
    public init(
        space: String,
        localization: String
    ) {
        self.space = space
        self.localization = localization
    }
}
