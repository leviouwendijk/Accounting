import Foundation

// (!): NOT USED BY ENTRY COMPILER
// look at ec-transaction.swift

public enum TransactionSource {
    case cash
    case bank
    case other
}

public struct TransactionParty {
    public let identifier: String // ? -> bank transaction, other bank transaction, cash transaction?
    public let name: String
    public let specifier: String
}

public struct Transaction {
    public let source: TransactionSource
    public let party: TransactionParty
    public let counterparty: TransactionParty
}
