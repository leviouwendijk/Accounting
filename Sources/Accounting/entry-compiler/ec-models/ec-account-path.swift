import Foundation

public struct AccountPath: Hashable, Codable, Sendable {
    public let segments: [String]
    public init(segments: [String]) { self.segments = segments }
}
