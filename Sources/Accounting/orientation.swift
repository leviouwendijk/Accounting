import Foundation

public enum AccountOrientation: String, Codable, Sendable {
    case regular
    case contra
}

public func checkBalanceOrientation(
    direction: Direction,
    balance: Double
) -> AccountOrientation { 
    switch direction {
    case .debit: 
        return (balance >= 0.0) ? .regular : .contra
    case .credit: 
        return (balance <= 0.0) ? .regular : .contra
    }
}

// helps see if a balance is according to the regular account orientation, or if it is inverted
// can determine where in the statements it is compiled to
// requires 'together' compiling of related 'omslag' accounts?
// compile the two balances by relating the account codes?
// aggregate balances together and determine where to display the balance in the statements
// set the other as 0?
