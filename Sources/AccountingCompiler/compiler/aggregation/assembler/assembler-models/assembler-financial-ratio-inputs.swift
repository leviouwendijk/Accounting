import Accounting
import Foundation

public struct FinancialRatioInputs: Sendable {
    public let assets: Decimal
    public let equity: Decimal
    public let liabilities: Decimal

    public let netTurnover: Decimal?
    public let costOfRevenue: Decimal?
    public let operatingExpenses: Decimal?
    public let depreciationExpenses: Decimal?
    public let financialResult: Decimal?
    public let netIncome: Decimal?

    public let liquidAssets: Decimal?
    public let shortTermSecurities: Decimal?
    public let receivables: Decimal?
    public let accruedCurrentAssets: Decimal?
    public let inventory: Decimal?
    public let workInProgress: Decimal?

    /// Short-term liabilities excluding accrued-current-liability bucket.
    public let currentLiabilities: Decimal?
    public let accruedCurrentLiabilities: Decimal?

    public init(
        assets: Decimal,
        equity: Decimal,
        liabilities: Decimal,
        netTurnover: Decimal?,
        costOfRevenue: Decimal?,
        operatingExpenses: Decimal?,
        depreciationExpenses: Decimal?,
        financialResult: Decimal?,
        netIncome: Decimal?,
        liquidAssets: Decimal?,
        shortTermSecurities: Decimal?,
        receivables: Decimal?,
        accruedCurrentAssets: Decimal?,
        inventory: Decimal?,
        workInProgress: Decimal?,
        currentLiabilities: Decimal?,
        accruedCurrentLiabilities: Decimal?
    ) {
        self.assets = assets
        self.equity = equity
        self.liabilities = liabilities
        self.netTurnover = netTurnover
        self.costOfRevenue = costOfRevenue
        self.operatingExpenses = operatingExpenses
        self.depreciationExpenses = depreciationExpenses
        self.financialResult = financialResult
        self.netIncome = netIncome
        self.liquidAssets = liquidAssets
        self.shortTermSecurities = shortTermSecurities
        self.receivables = receivables
        self.accruedCurrentAssets = accruedCurrentAssets
        self.inventory = inventory
        self.workInProgress = workInProgress
        self.currentLiabilities = currentLiabilities
        self.accruedCurrentLiabilities = accruedCurrentLiabilities
    }

    public var grossProfit: Decimal? {
        guard let netTurnover, let costOfRevenue else {
            return nil
        }

        return netTurnover - costOfRevenue
    }

    public var totalBusinessExpenses: Decimal? {
        Self.sumAvailable(
            operatingExpenses,
            depreciationExpenses
        )
    }

    public var operatingResult: Decimal? {
        guard let grossProfit, let totalBusinessExpenses else {
            return nil
        }

        return grossProfit - totalBusinessExpenses
    }

    public var totalCurrentAssets: Decimal? {
        Self.sumAvailable(
            liquidAssets,
            shortTermSecurities,
            receivables,
            accruedCurrentAssets,
            inventory,
            workInProgress
        )
    }

    public var quickAssets: Decimal? {
        guard let totalCurrentAssets else {
            return nil
        }

        return totalCurrentAssets
            - (inventory ?? 0)
            - (workInProgress ?? 0)
    }

    public var totalCurrentLiabilities: Decimal? {
        Self.sumAvailable(
            currentLiabilities,
            accruedCurrentLiabilities
        )
    }

    @inline(__always)
    private static func sumAvailable(
        _ values: Decimal?...
    ) -> Decimal? {
        let present = values.compactMap { $0 }

        guard !present.isEmpty else {
            return nil
        }

        return present.reduce(0, +)
    }
}
