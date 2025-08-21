import Foundation

public struct ResolvedLine: Hashable, Codable, Sendable {
    public let entity: EntityKey
    public let account: AccountPath
    public let direction: Direction
    public let amount: Decimal
    public let adjustment: InventoryAdjustment?
    
    public init(
        entity: EntityKey,
        account: AccountPath,
        direction: Direction,
        amount: Decimal,
        adjustment: InventoryAdjustment?
    ) {
        self.entity = entity
        self.account = account
        self.direction = direction
        self.amount = amount
        self.adjustment = adjustment
    }
}

public struct ResolvedEntry: Hashable, Codable, Sendable {
    public var id: Int?
    public var date: DateSpecification
    public var lines: [ResolvedLine]
    public var details: String?
    public var timezone: String?
    public var transactionReferences: [EntryCompilerTransactionID]
    
    public init(
        id: Int?,
        date: DateSpecification,
        lines: [ResolvedLine],
        details: String?,
        timezone: String?,
        transactionReferences: [EntryCompilerTransactionID]
    ) {
        self.id = id
        self.date = date
        self.lines = lines
        self.details = details
        self.timezone = timezone
        self.transactionReferences = transactionReferences
    }
}
