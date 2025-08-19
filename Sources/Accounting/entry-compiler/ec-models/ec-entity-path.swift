import Foundation

public struct EntityPath: Hashable, Codable, Sendable {
    public let domain: String            // "people"
    public let aliasSegments: [String]   // ["levi", "ouwendijk"]
    public init(domain: String, aliasSegments: [String]) {
        self.domain = domain
        self.aliasSegments = aliasSegments
    }

    public var alias: String { aliasSegments.joined(separator: "_") }
}

