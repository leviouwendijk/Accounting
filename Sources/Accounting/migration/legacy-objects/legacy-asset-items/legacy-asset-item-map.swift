import Foundation
import plate

// Handy mapping for "legacyAssetId -> preferred entity alias/unit + expense account"
public struct LegacyAssetMapping: Sendable, Codable {
    /// Entity (root) alias, e.g. "macbook"
    public let alias: String
    /// Unit alias, e.g. "levi_air_m2"
    public let unit: String
    /// Optional depreciation expense account code, e.g. "WAfsAmvBei"
    public let account: String?

    public init(alias: String, unit: String, account: String? = nil) {
        self.alias = alias
        self.unit = unit
        self.account = account
    }
}
