import Foundation

public struct RGSNameSpace: Hashable, Codable, Sendable { 
    public let id_code: String // such as "id_BImva" or whatever XBRL creates in xml
    public let space: String
    public let localization: String 
    
    public init(
        id_code: String,
        space: String,
        localization: String
    ) {
        self.id_code = id_code
        self.space = space
        self.localization = localization
    }
}
