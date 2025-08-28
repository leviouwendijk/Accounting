import Foundation

public struct RGSNodeCodes: Hashable, Sendable, Codable {
    public let code: String
    public let omslag: String?
    
    public init(
        code: String,
        omslag: String? = nil
    ) {
        self.code = code
        self.omslag = omslag
    }
}
