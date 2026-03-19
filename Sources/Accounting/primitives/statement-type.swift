import Foundation
import Primitives

public enum StatementKind: String, RawRepresentable, Codable, Sendable, StringParsableEnum {
    case income 
    case balance
    case cash
    case equity

    public var conventional: String {
        switch self {
        case .income: 
            return "income_statement"
        case .balance: 
            return "balance_sheet"
        case .cash: 
            return "cash_flow_statement"
        case .equity: 
            return "equity_view"
        }
    }

    public func from(conventional: String) throws -> Self {
        switch conventional {
        case Self.income.conventional:
            return .income
        case Self.balance.conventional:
            return .balance
        case Self.cash.conventional:
            return .cash
        case Self.equity.conventional:
            return .equity
        default:
            throw TypeInferenceError.invalidString(string: conventional, type: "StatementKind")
        }
    }
}
