import Foundation

public struct EntityDef: Sendable, Codable {
    public let key: EntityKey
    public var displayName: String?
    public var details: String?
    public var metadata: [String: String]
    public var profile: EntityUnitProfile?
    public var depreciation: DepreciationConfig?
    public var depreciationDraft: DepreciationConfigDraft?
    public var ownerEquity: OwnerEquity?

    public var kia: KIAConfigAssetAllocation?
    public var kiaDraft: KIADraft?

    public var location: SourceLocation?

    public init(
        key: EntityKey,
        displayName: String? = nil,
        details: String? = nil,
        metadata: [String: String] = [:],
        profile: EntityUnitProfile? = nil,
        depreciation: DepreciationConfig? = nil,
        depreciationDraft: DepreciationConfigDraft? = nil,
        ownerEquity: OwnerEquity? = nil,
        kia: KIAConfigAssetAllocation? = nil,
        kiaDraft: KIADraft? = nil,

        location: SourceLocation? = nil
    ) {
        self.key = key
        self.displayName = displayName
        self.details = details
        self.metadata = metadata
        self.profile = profile
        self.depreciation = depreciation
        self.depreciationDraft = depreciationDraft
        self.ownerEquity = ownerEquity
        self.kia = kia
        self.kiaDraft = kiaDraft
        self.location = location
    }
}
