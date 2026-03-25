import Foundation

public struct ResolvedLine: Hashable, Codable, Sendable {
    public let entity: EntityKey
    public let account: AccountKey
    public let direction: Direction
    public let amount: Decimal
    public let adjustment: InventoryAdjustment?

    public let location: SourceLocation?
    
    public init(
        entity: EntityKey,
        account: AccountKey,
        direction: Direction,
        amount: Decimal,
        adjustment: InventoryAdjustment?,

        location: SourceLocation? = nil
    ) {
        self.entity = entity
        self.account = account
        self.direction = direction
        self.amount = amount
        self.adjustment = adjustment

        self.location = location
    }
}

public struct ResolvedEntry: Hashable, Codable, Sendable {
    public var id: Int?
    public var date: DateSpecification
    public var lines: [ResolvedLine]
    public var details: String?
    public var timezone: String?
    public var metadata: [String: String]
    public var transactionReferences: [TransactionKey]

    public var location: SourceLocation?
    public var mistake: Mistake?
    public var select: EntrySelect?
    public var verbose: Bool

    
    public init(
        id: Int?,
        date: DateSpecification,
        lines: [ResolvedLine],
        details: String?,
        timezone: String?,
        metadata: [String: String],
        transactionReferences: [TransactionKey],

        location: SourceLocation? = nil,
        mistake: Mistake? = nil,
        select: EntrySelect? = nil,
        verbose: Bool = false
    ) {
        self.id = id
        self.date = date
        self.lines = lines
        self.details = details
        self.timezone = timezone
        self.metadata = metadata
        self.transactionReferences = transactionReferences

        self.location = location
        self.mistake = mistake
        self.select = select
        self.verbose = verbose
    }

    @inlinable
    public func assertBalancing() throws {
        var sum: Decimal = 0
        for l in lines {
            sum += (l.direction == .debit ? +l.amount : -l.amount)
        }
        if sum != 0 {
            throw CompilingAssertionError.unbalanced(id: id, delta: sum)
        }
    }
}
