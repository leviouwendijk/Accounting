import Foundation

public struct LegacyMap: Sendable, Codable {
    public let legacyId: Int
    public let legacyName: String // for context quick look
    public let account: String // -> AccountRef -> AccountKey / RGSNode?
    public let entity: String // -> EntityRef -> EntityKey
    
    public init(
        legacyId: Int,
        legacyName: String,
        account: String,
        entity: String
    ) {
        self.legacyId = legacyId
        self.legacyName = legacyName
        self.account = account
        self.entity = entity
    }

    public init(
        _ legacyId: Int,
        _ legacyName: String,
        _ RGSAccountIdentifier: String,
        _ localEntity: String
    ) {
        self.legacyId = legacyId
        self.legacyName = legacyName
        self.account = RGSAccountIdentifier
        self.entity = localEntity
    }
}

public enum LegacyTranslation {
    public static let rgs_v3_8: [LegacyMap] = [

    ]
}
