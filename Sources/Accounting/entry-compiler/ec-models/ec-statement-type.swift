import Foundation
import Extensions

public enum StatementType: String, RawRepresentable, Codable, Sendable, StringParsableEnum {
    case income 
    case balance
    case cash

    public var conventional: String {
        switch self {
        case .income: 
            return "income_statement"
        case .balance: 
            return "balance_sheet"
        case .cash: 
            return "cash_flow_statement"
        }
    }

    public func from(conventional: String) throws -> Self {
        switch conventional {
        case "income_statement":
            return .income
        case "balance_sheet":
            return .balance
        case "cash_flow_statement":
            return .cash
        default:
            throw TypeInferenceError.invalidString(string: conventional, type: "StatementType")
        }
    }
}
