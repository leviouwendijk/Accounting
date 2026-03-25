import Foundation

public struct AccountKey: Hashable, Codable, Sendable {
    public let code: String
    public init(_ code: String) { self.code = code }

    @inlinable public var intValue: Int? { Int(code) }
}
