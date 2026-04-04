import Foundation

public struct StatementBundle: Sendable, PresentableOutput {
    public let balance: [StatementLine]
    public let income: [StatementLine]
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

extension StatementBundle {
    public func withAnalytics(
        _ analytics: BundleAnalytics?
    ) -> StatementBundle {
        .init(
            balance: balance,
            income: income,
            totalsById: totalsById,
            entity: entity,
            analytics: analytics
        )
    }
}
