import Foundation

public struct FinancialRatios: Sendable {
    public let assets: Decimal
    public let equity: Decimal
    public let liabilities: Decimal
    public let netIncome: Decimal?

    public let equityRatio: Decimal?
    public let debtRatio: Decimal?
    public let debtToEquity: Decimal?
    public let equityMultiplier: Decimal?

    public let currentRatio: Decimal?
    public let quickRatio: Decimal?

    public let grossMargin: Decimal?
    public let operatingMargin: Decimal?
    public let netMargin: Decimal?

    public let returnOnAssets: Decimal?
    public let returnOnEquity: Decimal?

    public init(
        assets: Decimal,
        equity: Decimal,
        liabilities: Decimal,
        netIncome: Decimal?,
        equityRatio: Decimal?,
        debtRatio: Decimal?,
        debtToEquity: Decimal?,
        equityMultiplier: Decimal?,
        currentRatio: Decimal?,
        quickRatio: Decimal?,
        grossMargin: Decimal?,
        operatingMargin: Decimal?,
        netMargin: Decimal?,
        returnOnAssets: Decimal?,
        returnOnEquity: Decimal?
    ) {
        self.assets = assets
        self.equity = equity
        self.liabilities = liabilities
        self.netIncome = netIncome
        self.equityRatio = equityRatio
        self.debtRatio = debtRatio
        self.debtToEquity = debtToEquity
        self.equityMultiplier = equityMultiplier
        self.currentRatio = currentRatio
        self.quickRatio = quickRatio
        self.grossMargin = grossMargin
        self.operatingMargin = operatingMargin
        self.netMargin = netMargin
        self.returnOnAssets = returnOnAssets
        self.returnOnEquity = returnOnEquity
    }
}
