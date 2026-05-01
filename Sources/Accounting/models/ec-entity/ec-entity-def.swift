import Foundation
import Position

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

    public var collapses: Bool?

    public var location: Position?

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
        collapses: Bool? = nil,

        location: Position? = nil
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

extension EntityDef {
    @inline(__always)
    public var effectiveDisplayName: String? {
        let trimmed = displayName?.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard let trimmed, !trimmed.isEmpty else {
            return nil
        }

        return trimmed
    }

    @inline(__always)
    public var effectiveDetails: String? {
        let primary = details?.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        if let primary, !primary.isEmpty {
            return primary
        }

        let legacy = metadata["details"]?.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard let legacy, !legacy.isEmpty else {
            return nil
        }

        return legacy
    }
}
