import Foundation

public struct AssetsOverview: PresentableOutput {
    public let period: PeriodWindow
    public let rows: [AssetsOverviewRow]
    public let groups: [AssetsOverviewGroup]
    public let summary: AssetsOverviewSummary
    public let diagnosticCounts: [String: Int]

    public init(
        period: PeriodWindow,
        rows: [AssetsOverviewRow],
        groups: [AssetsOverviewGroup],
        summary: AssetsOverviewSummary,
        diagnosticCounts: [String: Int]
    ) {
        self.period = period
        self.rows = rows
        self.groups = groups
        self.summary = summary
        self.diagnosticCounts = diagnosticCounts
    }
}

public struct AssetsOverviewAmounts: Sendable {
    public let acquisitionCost: Decimal
    public let openingCarryingAmount: Decimal
    public let periodInvestment: Decimal
    public let periodDepreciation: Decimal
    public let closingCarryingAmount: Decimal
    public let residualAmount: Decimal

    public init(
        acquisitionCost: Decimal,
        openingCarryingAmount: Decimal,
        periodInvestment: Decimal,
        periodDepreciation: Decimal,
        closingCarryingAmount: Decimal,
        residualAmount: Decimal
    ) {
        self.acquisitionCost = acquisitionCost
        self.openingCarryingAmount = openingCarryingAmount
        self.periodInvestment = periodInvestment
        self.periodDepreciation = periodDepreciation
        self.closingCarryingAmount = closingCarryingAmount
        self.residualAmount = residualAmount
    }
}

public struct AssetsOverviewLine: Sendable {
    public let category: AssetsOverviewCategory
    public let name: String
    public let rows: [AssetsOverviewRow]
    public let flaggedAssetCount: Int
    public let totals: AssetsOverviewAmounts

    public init(
        category: AssetsOverviewCategory,
        name: String,
        rows: [AssetsOverviewRow],
        flaggedAssetCount: Int,
        totals: AssetsOverviewAmounts
    ) {
        self.category = category
        self.name = name
        self.rows = rows
        self.flaggedAssetCount = flaggedAssetCount
        self.totals = totals
    }
}

public struct AssetsOverviewSummary: Sendable {
    public let assetCount: Int
    public let flaggedAssetCount: Int
    public let totals: AssetsOverviewAmounts

    public let unclassifiedNonZeroAssetCount: Int
    public let unclassifiedNonZeroTotals: AssetsOverviewAmounts

    public init(
        assetCount: Int,
        flaggedAssetCount: Int,
        totals: AssetsOverviewAmounts,
        unclassifiedNonZeroAssetCount: Int,
        unclassifiedNonZeroTotals: AssetsOverviewAmounts
    ) {
        self.assetCount = assetCount
        self.flaggedAssetCount = flaggedAssetCount
        self.totals = totals
        self.unclassifiedNonZeroAssetCount = unclassifiedNonZeroAssetCount
        self.unclassifiedNonZeroTotals = unclassifiedNonZeroTotals
    }
}

public struct AssetsOverviewGroup: Sendable {
    public let section: AssetsOverviewSection
    public let name: String
    public let totalLabel: String
    public let lines: [AssetsOverviewLine]
    public let flaggedAssetCount: Int
    public let totals: AssetsOverviewAmounts

    public init(
        section: AssetsOverviewSection,
        name: String,
        totalLabel: String,
        lines: [AssetsOverviewLine],
        flaggedAssetCount: Int,
        totals: AssetsOverviewAmounts
    ) {
        self.section = section
        self.name = name
        self.totalLabel = totalLabel
        self.lines = lines
        self.flaggedAssetCount = flaggedAssetCount
        self.totals = totals
    }
}

public struct AssetsOverviewRow: Sendable {
    public let entityKey: EntityKey
    public let displayName: String
    public let details: String?

    // public let group: String
    public let category: AssetsOverviewCategory
    public let type: String?

    public let acquisitionDate: Date?
    public let commissionDate: Date?

    public let acquisitionCost: Decimal?
    public let usefulLifeYears: Decimal?
    public let residualPercentage: Decimal?
    public let residualAmount: Decimal?

    public let depreciationAccountCode: String?
    public let contraAccountCode: String?

    public let openingCarryingAmount: Decimal
    public let periodInvestment: Decimal
    public let periodDepreciation: Decimal
    public let closingCarryingAmount: Decimal

    public let ownerShares: [KIAAssetShare]
    public let flags: [String]

    public init(
        entityKey: EntityKey,
        displayName: String,
        details: String?,
        category: AssetsOverviewCategory,
        type: String?,
        acquisitionDate: Date?,
        commissionDate: Date?,
        acquisitionCost: Decimal?,
        usefulLifeYears: Decimal?,
        residualPercentage: Decimal?,
        residualAmount: Decimal?,
        depreciationAccountCode: String?,
        contraAccountCode: String?,
        openingCarryingAmount: Decimal,
        periodInvestment: Decimal,
        periodDepreciation: Decimal,
        closingCarryingAmount: Decimal,
        ownerShares: [KIAAssetShare],
        flags: [String]
    ) {
        self.entityKey = entityKey
        self.displayName = displayName
        self.details = details
        self.category = category
        self.type = type
        self.acquisitionDate = acquisitionDate
        self.commissionDate = commissionDate
        self.acquisitionCost = acquisitionCost
        self.usefulLifeYears = usefulLifeYears
        self.residualPercentage = residualPercentage
        self.residualAmount = residualAmount
        self.depreciationAccountCode = depreciationAccountCode
        self.contraAccountCode = contraAccountCode
        self.openingCarryingAmount = openingCarryingAmount
        self.periodInvestment = periodInvestment
        self.periodDepreciation = periodDepreciation
        self.closingCarryingAmount = closingCarryingAmount
        self.ownerShares = ownerShares
        self.flags = flags
    }
}
