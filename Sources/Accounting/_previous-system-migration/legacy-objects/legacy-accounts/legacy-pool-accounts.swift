import Foundation
import Primitives

public typealias PoolAccountsPage    = ExportPage<PoolAccount>

public struct PoolAccount: Codable, Sendable, JSONReadable, JSONWritable, Identifiable {
    public let id: Int
    public let name: String
    public let parent: Int
    public let description: String?
}
