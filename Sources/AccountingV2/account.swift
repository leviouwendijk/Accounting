import Foundation
import Primitives

/// One locally valid account definition. Chart membership is established separately.
public struct Account: Invariant, Sendable {
    public struct Raw: Sendable {
        public let code: String
        public let label: String?
        public let category: AccountCategory?
        public let postable: Bool

        public init(
            code: String,
            label: String? = nil,
            category: AccountCategory? = nil,
            postable: Bool
        ) {
            self.code = code
            self.label = label
            self.category = category
            self.postable = postable
        }
    }

    public enum Error: Swift.Error, Equatable, Sendable {
        case invalidReference
        case emptyLabel
        case missingPostableCategory
    }

    public struct Reference: Invariant, Hashable, Sendable {
        public enum Error: Swift.Error, Equatable, Sendable {
            case empty
        }

        public let code: String

        public init(_ raw: String) throws(Error) {
            guard !raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw .empty
            }
            self.code = raw
        }
    }

    public let reference: Reference
    public let label: String?
    public let category: AccountCategory?
    public let postable: Bool

    public init(_ raw: Raw) throws(Error) {
        guard let reference = try? Reference(raw.code) else {
            throw .invalidReference
        }
        if let label = raw.label,
            label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        {
            throw .emptyLabel
        }
        guard !raw.postable || raw.category != nil else {
            throw .missingPostableCategory
        }
        self.reference = reference
        self.label = raw.label
        self.category = raw.category
        self.postable = raw.postable
    }

    public var code: String { reference.code }
}
