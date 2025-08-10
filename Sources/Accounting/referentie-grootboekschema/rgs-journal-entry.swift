import Foundation

public struct RGSJournalEntry {
    public let id: String
    public let date: Date
    public let description: String
    public var postings: [RGSPosting]

    public init(
        id: String, 
        date: Date, 
        description: String, 
        postings: [RGSPosting]
    ) {
        self.id = id
        self.date = date
        self.description = description
        self.postings = postings
    }
}

public struct RGSPosting {
    public let account: RGSAccount
    public let entity: Entity
    public let amount: Double
    public let mutation: Direction
    public let adjustments: [InventoryAdjustment]?

    public init(
        account: RGSAccount, 
        entity: Entity,
        amount: Double, 
        mutation: Direction,
        adjustments: [InventoryAdjustment]? = nil
    ) {
        self.account = account
        self.entity = entity
        self.amount = amount
        self.mutation = mutation
        self.adjustments = adjustments
    }
}
