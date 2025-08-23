import Foundation

public enum TransactionSource: String, Codable, Sendable {
    case bunq, cash, bank, card, manual, `import`, `private`
}

public enum TransactionStatus: String, Codable, Sendable {
    case pending, cleared, reconciled, voided
}

public struct TransactionIdentifiers: Codable, Sendable {
    public var platformAccountID: Int?
    public var platformTransactionID: Int?
    public init(platformAccountID: Int? = nil, platformTransactionID: Int? = nil) {
        self.platformAccountID = platformAccountID
        self.platformTransactionID = platformTransactionID
    }
}

public struct TransactionAmount: Codable, Sendable {
    public var currency: String
    public var gross: Decimal
    public var fee: Decimal?
    public var net: Decimal?
    public init(currency: String, gross: Decimal, fee: Decimal? = nil, net: Decimal? = nil) {
        self.currency = currency
        self.gross = gross
        self.fee = fee
        self.net = net
    }
}

public struct TransactionCounterparty: Codable, Sendable {
    public var name: String?
    public var iban: String?
    public var bic: String?
    public init(name: String? = nil, iban: String? = nil, bic: String? = nil) {
        self.name = name
        self.iban = iban
        self.bic = bic
    }
}

public struct Transaction: Codable, Sendable {
    public var id: Int?
    public var date: DateSpecification
    public var source: TransactionSource
    public var identifiers: TransactionIdentifiers
    public var amount: TransactionAmount
    public var details: String?
    public var counterparty: TransactionCounterparty?
    public var metadata: [String:String]
    public var status: TransactionStatus

    public init(
        id: Int? = nil,
        date: DateSpecification,
        source: TransactionSource,
        identifiers: TransactionIdentifiers = .init(),
        amount: TransactionAmount,
        details: String? = nil,
        counterparty: TransactionCounterparty? = nil,
        metadata: [String:String] = [:],
        status: TransactionStatus
    ) {
        self.id = id
        self.date = date
        self.source = source
        self.identifiers = identifiers
        self.amount = amount
        self.details = details
        self.counterparty = counterparty
        self.metadata = metadata
        self.status = status
    }
}
