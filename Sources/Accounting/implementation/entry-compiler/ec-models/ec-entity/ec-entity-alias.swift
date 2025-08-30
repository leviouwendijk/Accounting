import Foundation

public struct EntityAlias: Hashable, Codable, Sendable {
    public let name: String
    public let variant: [String]?

    public init(
        name: String,
        variant: [String]? = nil
    ) {
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
