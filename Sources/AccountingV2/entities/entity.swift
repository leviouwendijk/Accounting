import Foundation
import Primitives

public struct Entity: Invariant, Sendable {
    public struct Alias: Invariant, Hashable, Sendable {
        public struct Raw: Sendable {
            public let name: String
            public let variants: [String]

            public init(name: String, variants: [String] = []) {
                self.name = name
                self.variants = variants
            }
        }

        public enum Error: Swift.Error, Equatable, Sendable {
            case invalidName
            case invalidVariant(Int)
        }

        public let name: String
        public let variants: [String]

        public init(_ raw: Raw) throws(Error) {
            func valid(_ value: String) -> Bool {
                !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    && !value.contains(".")
                    && !value.contains("#")
            }

            guard valid(raw.name) else { throw .invalidName }
            for (index, variant) in raw.variants.enumerated() {
                guard valid(variant) else { throw .invalidVariant(index) }
            }
            self.name = raw.name
            self.variants = raw.variants
        }

        public init(name: String, variants: [String] = []) throws(Error) {
            try self.init(.init(name: name, variants: variants))
        }

        public var identifier: String {
            ([name] + variants).joined(separator: "#")
        }
    }

    public struct Reference: Invariant, Hashable, Sendable {
        public struct Raw: Sendable {
            public let `class`: String
            public let family: String
            public let alias: Alias

            public init(class: String, family: String, alias: Alias) {
                self.`class` = `class`
                self.family = family
                self.alias = alias
            }
        }

        public enum Error: Swift.Error, Equatable, Sendable {
            case invalidClass
            case invalidFamily
        }

        public let `class`: String
        public let family: String
        public let alias: Alias

        public init(_ raw: Raw) throws(Error) {
            func valid(_ value: String) -> Bool {
                !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    && !value.contains(".")
                    && !value.contains("#")
            }

            guard valid(raw.class) else { throw .invalidClass }
            guard valid(raw.family) else { throw .invalidFamily }

            self.`class` = raw.class
            self.family = raw.family
            self.alias = raw.alias
        }

        public init(class: String, family: String, alias: Alias) throws(Error) {
            try self.init(.init(class: `class`, family: family, alias: alias))
        }

        public var identifier: String {
            [`class`, family, alias.identifier].joined(separator: ".")
        }
    }

    public struct Raw: Sendable {
        public let reference: Reference
        public let displayName: String?
        public let details: String?
        public let metadata: [String: String]

        public init(
            reference: Reference,
            displayName: String? = nil,
            details: String? = nil,
            metadata: [String: String] = [:]
        ) {
            self.reference = reference
            self.displayName = displayName
            self.details = details
            self.metadata = metadata
        }
    }

    public enum Error: Swift.Error, Equatable, Sendable {
        case emptyDisplayName
        case emptyDetails
    }

    public let reference: Reference
    public let displayName: String?
    public let details: String?
    public let metadata: [String: String]

    public init(_ raw: Raw) throws(Error) {
        if let name = raw.displayName,
            name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        {
            throw .emptyDisplayName
        }

        if let details = raw.details,
            details.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        {
            throw .emptyDetails
        }

        self.reference = raw.reference
        self.displayName = raw.displayName
        self.details = raw.details
        self.metadata = raw.metadata
    }
}
