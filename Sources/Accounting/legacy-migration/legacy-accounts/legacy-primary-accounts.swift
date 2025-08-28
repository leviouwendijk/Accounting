import Foundation
import plate

public typealias PrimaryAccountsPage = ExportPage<PrimaryAccount>

public struct PrimaryAccount: Codable, Sendable, JSONReadable, JSONWritable, Identifiable {
    public let id: Int
    public let name: String
    public let parent: Int
    public let description: String?
    public let relatedPrimaryAccountID: Int?

    enum CodingKeys: String, CodingKey {
        case id, name, parent, description
        case relatedPrimaryAccountID = "related_primary_account_id"
    }
}

