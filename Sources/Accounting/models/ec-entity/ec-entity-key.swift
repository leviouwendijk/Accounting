import Foundation

public struct EntityKey: Hashable, Codable, Sendable {
    public let `class`: String      // e.g. "objects"
    public let family: String       // e.g. "usable"
    public let alias: EntityAlias   // e.g. macbook#levi_air_m2

    public init(class: String, family: String, alias: EntityAlias) {
        self.`class` = `class`
        self.family = family 
        self.alias = alias
    }

    public enum AliasType { case root, fullchain }

    public func identifier(displaying t: AliasType) -> String {
        switch t {
        case .root:      return [`class`, family, alias.name].joined(separator: ".")
        case .fullchain: return [`class`, family, alias.string].joined(separator: ".")
        }
    }
}

// public struct EntityPath: Hashable, Codable, Sendable {
//     public let domain: String            // "people"
//     public let aliasSegments: [String]   // ["levi", "ouwendijk"]
//     public init(domain: String, aliasSegments: [String]) {
//         self.domain = domain
//         self.aliasSegments = aliasSegments
//     }

//     public var alias: String { aliasSegments.joined(separator: "_") }

//     public var ecString: String { ([domain] + aliasSegments).joined(separator: ".") }
// }
