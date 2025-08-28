import Foundation
import plate

public struct ExportPage<Row: Codable & Sendable>: Codable, Sendable, JSONReadable, JSONWritable {
    public let checksum: String
    public let exportID: String
    public let generatedAt: String
    public let page: Int
    public let perPage: Int
    public let rows: [Row]
    public let schemaVersion: String
    public let table: String
    public let total: Int
    public let totalPages: Int

    enum CodingKeys: String, CodingKey {
        case checksum
        case exportID = "export_id"
        case generatedAt = "generated_at"
        case page, rows, table, total
        case perPage = "per_page"
        case schemaVersion = "schema_version"
        case totalPages = "total_pages"
    }
}

