import Foundation
import Primitives

public struct EntityKey: Invariant, Hashable, Codable, Sendable {
    public struct Raw: Sendable, Hashable {
        public let `class`: String
        public let family: String
        public let alias: EntityAlias

        public init(class: String, family: String, alias: EntityAlias) {
            self.`class` = `class`
            self.family = family
            self.alias = alias
        }
    }

    public enum Error: Swift.Error, Sendable, Equatable {
        case invalidClass
        case invalidFamily
    }

    public let `class`: String
    public let family: String
    public let alias: EntityAlias

    public init(_ raw: Raw) throws(Error) {
        func validPathComponent(_ s: String) -> Bool {
            !s.isEmpty && !s.allSatisfy(\.isWhitespace) && !s.contains(".") && !s.contains("#")
        }
        guard validPathComponent(raw.class) else { throw .invalidClass }
        guard validPathComponent(raw.family) else { throw .invalidFamily }
        self.`class` = raw.class
        self.family = raw.family
        self.alias = raw.alias
    }

    public init(class: String, family: String, alias: EntityAlias) throws(Error) {
        try self.init(Raw(class: `class`, family: family, alias: alias))
    }

    public enum AliasType { case root, fullchain }

    public func identifier(displaying t: AliasType) -> String {
        switch t {
        case .root:      return [`class`, family, alias.name].joined(separator: ".")
        case .fullchain: return [`class`, family, alias.string].joined(separator: ".")
        }
    }

    private enum CodingKeys: String, CodingKey { case `class`, family, alias }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let c = try container.decode(String.self, forKey: .class)
        let family = try container.decode(String.self, forKey: .family)
        let alias = try container.decode(EntityAlias.self, forKey: .alias)
        do { try self.init(class: c, family: family, alias: alias) }
        catch {
            throw DecodingError.dataCorruptedError(
                forKey: .class, in: container,
                debugDescription: "Invalid entity key: \(error)"
            )
        }
    }
}
