import Foundation
import Primitives

public struct AccountPath: Invariant, Hashable, Codable, Sendable {
    public struct Raw: Sendable, Hashable {
        public let segments: [String]
        public init(_ segments: [String]) { self.segments = segments }
    }

    public enum Error: Swift.Error, Sendable, Equatable {
        case empty
        case emptySegment(index: Int)
        case embeddedSeparator(index: Int)
    }

    public let segments: [String]

    public init(_ raw: Raw) throws(Error) {
        guard !raw.segments.isEmpty else { throw .empty }
        for (index, segment) in raw.segments.enumerated() {
            guard !segment.isEmpty, !segment.allSatisfy(\.isWhitespace) else {
                throw .emptySegment(index: index)
            }
            guard !segment.contains(".") else { throw .embeddedSeparator(index: index) }
        }
        self.segments = raw.segments
    }

    public init(segments: [String]) throws(Error) {
        try self.init(Raw(segments))
    }

    // Preserve the original keyed {"segments": [...]} Codable representation.
    private enum CodingKeys: String, CodingKey { case segments }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let segments = try container.decode([String].self, forKey: .segments)
        do { try self.init(segments: segments) }
        catch {
            throw DecodingError.dataCorruptedError(
                forKey: .segments, in: container,
                debugDescription: "Invalid account path segments: \(error)"
            )
        }
    }
}
