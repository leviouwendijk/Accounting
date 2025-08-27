import Foundation

public struct RGSNodeLabels: Sendable, Codable {
    public let short: String
    public let long: String
    
    public init(
        short: String,
        long: String
    ) {
        self.short = short
        self.long = long
    }
}
