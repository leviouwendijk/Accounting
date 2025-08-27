import Foundation

public struct RGSNodeCodes: Hashable, Sendable, Codable {
    public let id_code: String
    public let code: String
    public let omslag: String?
    
    public init(
        id_code: String, 
        code: String,
        omslag: String? = nil
    ) {
        self.id_code = id_code
        self.code = code
        self.omslag = omslag
    }
}
