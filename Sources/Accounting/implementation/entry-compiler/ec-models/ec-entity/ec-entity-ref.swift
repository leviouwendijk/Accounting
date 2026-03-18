import Foundation

// Possibly-partial reference from entries: 1..3 segments allowed
public struct EntityRef: Hashable, Codable, Sendable {
    public let `class`: String?
    public let family: String?
    public let alias: EntityAlias

    public let placeholder: EntityPlaceholder?

    public init(
        class: String?,
        family: String?,
        alias: EntityAlias,
    ) {
        self.`class` = `class`
        self.family = family
        self.alias = alias
        self.placeholder = nil
    }

    public init(
        class: String? = nil,
        family: String? = nil,
        placeholder: EntityPlaceholder
    ) {
        self.`class` = `class`
        self.family = family
        self.alias = EntityAlias.parse(placeholder.loweredAlias)
        self.placeholder = placeholder
    }

    public var printable: String {
        if let placeholder {
            return "placeholder(\(placeholder.kind.rawValue))"
        }

        return [`class`, family, alias.string].compactMap { $0 }.joined(separator: ".")
    }
}
