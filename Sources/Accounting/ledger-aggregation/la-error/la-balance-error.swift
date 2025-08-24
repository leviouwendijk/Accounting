import Foundation

public enum BalanceSheetError: Error, CustomStringConvertible, Sendable {
    case assetsNotEqualLiabPlusEq(assets: Decimal, liabilitiesPlusEquity: Decimal)

    public var description: String {
        switch self {
        case let .assetsNotEqualLiabPlusEq(a, lpe):
            return "Balance Sheet mismatch: Assets \(a) vs Liab+Equity \(lpe)."
        }
    }
}
