import Accounting
import Foundation

public struct AssetSharesPeriodReport: Sendable {
    public let period: PeriodWindow
    public let openingCarryingAmount: Decimal
    public let periodInvestment: Decimal
    public let closingCarryingAmount: Decimal
    public let breakdown: [AssetsOverviewOwnerShareAmounts]

    public init(
        period: PeriodWindow,
        openingCarryingAmount: Decimal,
        periodInvestment: Decimal,
        closingCarryingAmount: Decimal,
        breakdown: [AssetsOverviewOwnerShareAmounts]
    ) {
        self.period = period
        self.openingCarryingAmount = openingCarryingAmount
        self.periodInvestment = periodInvestment
        self.closingCarryingAmount = closingCarryingAmount
        self.breakdown = breakdown
    }
}

public struct AssetSharesHistoryReport: PresentableOutput {
    public let title: String
    public let periods: [AssetSharesPeriodReport]

    public init(
        title: String,
        periods: [AssetSharesPeriodReport]
    ) {
        self.title = title
        self.periods = periods
    }
}
