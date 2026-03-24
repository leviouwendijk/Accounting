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

public struct AssetsOverviewSummary: Sendable {
    public let assetCount: Int
    public let flaggedAssetCount: Int

    public let acquisitionCostTotal: Decimal
    public let openingCarryingAmountTotal: Decimal
    public let periodInvestmentTotal: Decimal
    public let periodDepreciationTotal: Decimal
    public let closingCarryingAmountTotal: Decimal

    public init(
        assetCount: Int,
        flaggedAssetCount: Int,
        acquisitionCostTotal: Decimal,
        openingCarryingAmountTotal: Decimal,
        periodInvestmentTotal: Decimal,
        periodDepreciationTotal: Decimal,
        closingCarryingAmountTotal: Decimal
    ) {
        self.assetCount = assetCount
        self.flaggedAssetCount = flaggedAssetCount
        self.acquisitionCostTotal = acquisitionCostTotal
        self.openingCarryingAmountTotal = openingCarryingAmountTotal
        self.periodInvestmentTotal = periodInvestmentTotal
        self.periodDepreciationTotal = periodDepreciationTotal
        self.closingCarryingAmountTotal = closingCarryingAmountTotal
    }
}

public struct AssetsOverviewGroup: Sendable {
    public let category: AssetsOverviewCategory
    public let name: String
    public let rows: [AssetsOverviewRow]

    public init(
        name: String,
        category: AssetsOverviewCategory,
        rows: [AssetsOverviewRow]
    ) {
        self.name = name
        self.category = category
        self.rows = rows
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
