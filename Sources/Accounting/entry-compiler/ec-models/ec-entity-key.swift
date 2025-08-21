import Foundation

public struct EntityAlias: Hashable, Codable, Sendable {
    public let name: String
    public let variant: [String]?

    public init(name: String, variant: [String]? = nil) {
        self.name = name
        self.variant = variant
    }

    public var string: String {
        guard let v = variant, !v.isEmpty else { return name }
        return ([name] + v).joined(separator: "#")
    }

    // split "macbook#levi_air_m2#nl" → (name:"macbook", variant:["levi_air_m2","nl"])
    public static func parse(_ segment: String) -> EntityAlias {
        let parts = segment.split(separator: "#").map(String.init)
        let n = parts.first ?? segment
        let rest = parts.count > 1 ? Array(parts.dropFirst()) : []
        return .init(name: n, variant: rest.isEmpty ? nil : rest)
    }
}

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
