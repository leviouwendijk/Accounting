import Foundation

public struct TransactionKey: Hashable, Codable, Sendable {
    public let id: Int
    public init(_ id: Int) { self.id = id }
}
