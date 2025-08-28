import Foundation
import plate

public typealias SuperAccountsPage   = ExportPage<SuperAccount>

public struct SuperAccount: Codable, Sendable, JSONReadable, JSONWritable, Identifiable {
    public enum Side: String, Codable, Sendable {
        case debit  = "Debit"
        case credit = "Credit"
    }

    public enum Kind: String, Codable, Sendable {
        case temporary = "Temporary"
        case permanent = "Permanent"
    }

    public let id: Int
    public let name: String
    public let side: Side
    public let type: Kind
    public let description: String?
}
