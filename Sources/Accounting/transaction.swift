import Foundation

// (!): NOT USED BY ENTRY COMPILER
// look at ec-transaction.swift

public enum GenericTransactionSource {
    case cash
    case bank
    case other
}

public struct GenericTransactionParty {
    public let identifier: String // ? -> bank transaction, other bank transaction, cash transaction?
    public let name: String
    public let specifier: String
}

public struct GenericTransaction {
    public let source: GenericTransactionSource
    public let party: GenericTransactionParty
    public let counterparty: GenericTransactionParty
}
