import Foundation

public enum ClosingError: Error, CustomStringConvertible, Sendable {
    case missingNetIncomeAccount
    case missingDrawingsAccount

    public var description: String {
        switch self {
        case .missingNetIncomeAccount: return "No configured net-income (retained earnings) account."
        case .missingDrawingsAccount:  return "No configured drawings/distributions account."
        }
    }
}
