import Foundation
import Primitives

public struct AccountKey: Invariant, Hashable, Codable, Sendable {
    public struct Raw: Sendable, Hashable {
        public let code: String
        public init(_ code: String) { self.code = code }
    }

    public enum Error: Swift.Error, Sendable, Equatable {
        case empty
    }

    public let code: String

    public init(_ raw: Raw) throws(Error) {
        guard !raw.code.isEmpty, !raw.code.allSatisfy(\.isWhitespace) else {
            throw .empty
        }
        self.code = raw.code
    }

    public init(_ code: String) throws(Error) {
        try self.init(Raw(code))
    }

    // Preserve the original keyed {"code": ...} Codable representation.
    private enum CodingKeys: String, CodingKey { case code }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let code = try container.decode(String.self, forKey: .code)
        do { try self.init(code) }
        catch {
            throw DecodingError.dataCorruptedError(
                forKey: .code, in: container,
                debugDescription: "Account code cannot be empty"
            )
        }
    }

    @inlinable public var intValue: Int? { Int(code) }
}
