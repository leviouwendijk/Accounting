import Accounting
import Foundation

public enum IBVOFField: String, Sendable, Codable, CaseIterable {
    case netTurnover            = "net_turnover"
    case costOfRevenue          = "cost_of_revenue"
    case grossProfit            = "gross_profit"

    case operatingExpenses      = "operating_expenses"
    case depreciationExpenses   = "depreciation_expenses"
    case totalBusinessExpenses  = "total_business_expenses"
    case financialResult        = "financial_result"
    case netProfit              = "net_profit"

    case privateContributions   = "private_contributions"
    case privateWithdrawals     = "private_withdrawals"

    case assets                 = "assets"
    case equity                 = "equity"
    case liabilities            = "liabilities"
}
