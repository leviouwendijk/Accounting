import Foundation

public enum AcquiredAssetPurchaseDateSource: String, Codable, Sendable {
    case acquisitionDate
    case commissionDateFallback
}

public struct AcquiredAssetsReport: PresentableOutput {
    public let period: PeriodWindow
    public let anchor: Date
    public let rows: [AcquiredAssetRow]
    public let skippedMissingDateCount: Int
    public let totalAcquisitionCost: Decimal
    public let diagnosticCounts: [String: Int]

    public init(
        period: PeriodWindow,
        anchor: Date,
        rows: [AcquiredAssetRow],
        skippedMissingDateCount: Int,
        totalAcquisitionCost: Decimal,
        diagnosticCounts: [String: Int]
    ) {
        self.period = period
        self.anchor = anchor
        self.rows = rows
        self.skippedMissingDateCount = skippedMissingDateCount
        self.totalAcquisitionCost = totalAcquisitionCost
        self.diagnosticCounts = diagnosticCounts
    }
}

public struct AcquiredAssetRow: Sendable {
    public let entityKey: EntityKey
    public let displayName: String
    public let details: String?

    public let category: AssetsOverviewCategory
    public let type: String?

    public let purchaseDate: Date
    public let purchaseDateSource: AcquiredAssetPurchaseDateSource

    public let acquisitionDate: Date?
    public let commissionDate: Date?

    public let acquisitionCost: Decimal?
    public let purchaseEntry: String?

    public let ownerShares: [KIAAssetShare]
    public let issues: [AssetsOverviewIssue]
    public let flags: [String]

    public init(
        entityKey: EntityKey,
        displayName: String,
        details: String?,
        category: AssetsOverviewCategory,
        type: String?,
        purchaseDate: Date,
        purchaseDateSource: AcquiredAssetPurchaseDateSource,
        acquisitionDate: Date?,
        commissionDate: Date?,
        acquisitionCost: Decimal?,
        purchaseEntry: String?,
        ownerShares: [KIAAssetShare],
        issues: [AssetsOverviewIssue]
    ) {
        self.entityKey = entityKey
        self.displayName = displayName
        self.details = details
        self.category = category
        self.type = type
        self.purchaseDate = purchaseDate
        self.purchaseDateSource = purchaseDateSource
        self.acquisitionDate = acquisitionDate
        self.commissionDate = commissionDate
        self.acquisitionCost = acquisitionCost
        self.purchaseEntry = purchaseEntry
        self.ownerShares = ownerShares
        self.issues = issues
        self.flags = issues.map(\.message)
    }

    public var highestIssueSeverity: AssetsOverviewIssueSeverity? {
        issues.map(\.severity).max()
    }

    public var hasIssues: Bool {
        !issues.isEmpty
    }
}
