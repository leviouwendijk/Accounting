import Foundation
import plate

public typealias PrimaryAccountsPage = ExportPage<PrimaryAccount>

public struct PrimaryAccount: Codable, Sendable, JSONReadable, JSONWritable, Identifiable {
    public let id: Int
    public let name: String
    public let parent: Int
    public let description: String?
    public let relatedPrimaryAccountID: Int?
    
    public init(
        id: Int,
        name: String,
        parent: Int,
        description: String?,
        relatedPrimaryAccountID: Int?
    ) {
        self.id = id
        self.name = name
        self.parent = parent
        self.description = description
        self.relatedPrimaryAccountID = relatedPrimaryAccountID
    }

    enum CodingKeys: String, CodingKey {
        case id, name, parent, description
        case relatedPrimaryAccountID = "related_primary_account_id"
    }


    public func reprintedSwift() -> String {
        return """
        .init(
            \(id), 
            \"\(name.esc)\",
            \"acc\",
            \"ent\"
        ),\n
        """.indent(2)
    }
}

extension Array where Element == PrimaryAccount {
    public func reprintArray() -> String {
        var out = ""
        for i in self {
            out.append(i.reprintedSwift())
        }
        return out
    }
}
