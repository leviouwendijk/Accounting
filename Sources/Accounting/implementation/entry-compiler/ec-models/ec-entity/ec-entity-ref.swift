import Foundation

// Possibly-partial reference from entries: 1..3 segments allowed
public struct EntityRef: Hashable, Codable, Sendable {
    public let `class`: String?
    public let family: String?
    public let alias: EntityAlias

    public init(class: String?,
            family: String?,
            alias: EntityAlias
    ) {
        self.`class` = `class`
        self.family = family
        self.alias = alias
    }

    public var printable: String {
        [`class`, family, alias.string].compactMap { $0 }.joined(separator: ".")
    }
}
