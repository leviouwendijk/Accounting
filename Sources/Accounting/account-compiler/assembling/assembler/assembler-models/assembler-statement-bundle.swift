import Foundation

public struct BundleAnalytics: Sendable {
    public let l2Buckets: L2Buckets
    public let l2Totals: PresentedBalanceTotals
}

public struct StatementBundle: Sendable {
    public let balance: [StatementLine]
    public let income:  [StatementLine]
    public let totalsById: [Int: Decimal]
    public let entity: EntityBreakdown?
    public let analytics: BundleAnalytics?  

    public init(
        balance: [StatementLine],
        income: [StatementLine],
        totalsById: [Int: Decimal],
        entity: EntityBreakdown? = nil,
        analytics: BundleAnalytics? = nil
    ) {
        self.balance = balance
        self.income = income
        self.totalsById = totalsById
        self.entity = entity
        self.analytics = analytics
    }
}
