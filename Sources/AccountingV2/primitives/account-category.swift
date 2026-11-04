import Foundation

/// Chart-independent economic classification.
/// Does not determine native chart hierarchy or statement presentation.
public enum AccountCategory: String, Codable, Hashable, Sendable, CaseIterable {
    // DEALER
    // Dividends, Expenses, Assets, Liabilities, Equity, Revenue
    case dividends
    case expenses
    case assets
    case liabilities
    case equity
    case revenue

    // RED-ALE
    // Revenue, Expenses, Dividends -- Assets, Liabilities, Equity
    public var temporality: Temporality {
        switch self {
        case .revenue, .expenses, .dividends:
            return .duration

        case .assets, .liabilities, .equity:
            return .instant
        }
    }
}
