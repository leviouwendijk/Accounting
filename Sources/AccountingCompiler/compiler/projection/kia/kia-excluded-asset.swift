import Accounting
import Foundation

public struct KIAExcludedAsset: Sendable, Hashable {
    public let entityKey: EntityKey
    public let reason: KIAQualificationReason

    public init(
        entityKey: EntityKey,
        reason: KIAQualificationReason
    ) {
        self.entityKey = entityKey
        self.reason = reason
    }
}
