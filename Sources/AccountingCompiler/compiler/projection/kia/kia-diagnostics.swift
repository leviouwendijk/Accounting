import Accounting
import Foundation

public enum KIADiagnosticOutcome: Sendable, Hashable {
    case qualified
    case excluded(KIAQualificationReason)
}

public struct KIADiagnosticRecord: Sendable, Hashable {
    public let entityKey: EntityKey
    public let displayName: String
    public let wasCandidate: Bool
    public let commissionDate: Date?
    public let acquisitionCost: Decimal?
    public let shareSummary: String?
    public let outcome: KIADiagnosticOutcome

    public init(
        entityKey: EntityKey,
        displayName: String,
        wasCandidate: Bool,
        commissionDate: Date?,
        acquisitionCost: Decimal?,
        shareSummary: String?,
        outcome: KIADiagnosticOutcome
    ) {
        self.entityKey = entityKey
        self.displayName = displayName
        self.wasCandidate = wasCandidate
        self.commissionDate = commissionDate
        self.acquisitionCost = acquisitionCost
        self.shareSummary = shareSummary
        self.outcome = outcome
    }
}

public struct KIAAssessmentResult: Sendable {
    public let qualified: [KIAQualifiedAsset]
    public let excluded: [KIAExcludedAsset]
    public let diagnostics: [KIADiagnosticRecord]

    public init(
        qualified: [KIAQualifiedAsset],
        excluded: [KIAExcludedAsset],
        diagnostics: [KIADiagnosticRecord]
    ) {
        self.qualified = qualified
        self.excluded = excluded
        self.diagnostics = diagnostics
    }
}
