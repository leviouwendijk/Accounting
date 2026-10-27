import Foundation
import Primitives

public struct EntityAlias: Invariant, Hashable, Codable, Sendable {
    public struct Raw: Sendable, Hashable {
        public let name: String
        public let variant: [String]?

        public init(name: String, variant: [String]? = nil) {
            self.name = name
            self.variant = variant
        }
    }

    public enum Error: Swift.Error, Sendable, Equatable {
        case emptyName
        case invalidName
        case emptyVariants
        case emptyVariant(index: Int)
        case invalidVariant(index: Int)
    }

    public let name: String
    public let variant: [String]?

    public init(_ raw: Raw) throws(Error) {
        guard !raw.name.isEmpty, !raw.name.allSatisfy(\.isWhitespace) else {
            throw .emptyName
        }
        guard !raw.name.contains("#"), !raw.name.contains(".") else {
            throw .invalidName
        }
        if let variants = raw.variant {
            guard !variants.isEmpty else { throw .emptyVariants }
            for (index, value) in variants.enumerated() {
                guard !value.isEmpty, !value.allSatisfy(\.isWhitespace) else {
                    throw .emptyVariant(index: index)
                }
                guard !value.contains("#"), !value.contains(".") else {
                    throw .invalidVariant(index: index)
                }
            }
        }
        self.name = raw.name
        self.variant = raw.variant
    }

    public init(name: String, variant: [String]? = nil) throws(Error) {
        try self.init(Raw(name: name, variant: variant))
    }

    public var string: String {
        guard let variants = variant else { return name }
        return ([name] + variants).joined(separator: "#")
    }

    /// Parse every alias component; never discard empty `#` components.
    public static func parse(_ segment: String) throws(Error) -> EntityAlias {
        let parts = segment.split(separator: "#", omittingEmptySubsequences: false)
        let name = String(parts[0])
        let variants = parts.count > 1 ? parts.dropFirst().map(String.init) : nil
        return try EntityAlias(name: name, variant: variants)
    }

    public func appendingVariant(_ variant: String) throws(Error) -> EntityAlias {
        try EntityAlias(name: name, variant: (self.variant ?? []) + [variant])
    }

    private enum CodingKeys: String, CodingKey { case name, variant }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let name = try container.decode(String.self, forKey: .name)
        let variant = try container.decodeIfPresent([String].self, forKey: .variant)
        do { try self.init(name: name, variant: variant) }
        catch {
            throw DecodingError.dataCorruptedError(
                forKey: .name, in: container,
                debugDescription: "Invalid entity alias: \(error)"
            )
        }
    }
}
