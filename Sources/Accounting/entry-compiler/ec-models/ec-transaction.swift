import Foundation

public typealias EntryCompilerTransactionID = Int

public enum EntryCompilerTransactionSource: String, Codable, Sendable {
    case bunq, cash, bank, card, manual, `import`, `private`
}

public struct EntryCompilerTransactionIdentifiers: Codable, Sendable {
    public var platformAccountID: String?
    public var platformEntryCompilerTransactionID: String?
    public var extra: [String:String] = [:]
}

public enum EntryCompilerTransactionStatus: String, Codable, Sendable {
    case pending, cleared, reconciled, voided
}

public struct EntryCompilerTransactionMonetaryAmount: Codable, Sendable {
    public var currency: String
    public var gross: Decimal
    public var fee: Decimal?
    public var net: Decimal?
}

public struct EntryCompilerTransactionCounterparty: Codable, Sendable {
    public var name: String?
    public var iban: String?
    public var bic: String?
}

public struct EntryCompilerTransaction: Codable, Sendable {
    public let id: EntryCompilerTransactionID          // GLOBAL integer
    public let date: DateSpecification
    public let source: EntryCompilerTransactionSource
    public var identifiers: EntryCompilerTransactionIdentifiers
    public var amount: EntryCompilerTransactionMonetaryAmount
    // public var memo: String?
    public var details: String?
    public var counterparty: EntryCompilerTransactionCounterparty?
    public var status: EntryCompilerTransactionStatus
}
