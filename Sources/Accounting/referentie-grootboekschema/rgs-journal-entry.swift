import Foundation

// in ec-models/ec-entry.swift

public struct RGSJournalEntry {
    public let id: Int
    public let date: Date
    public let description: String
    public var postings: [RGSPosting]
    // public var transactionReferences: [EntryCompilerTransactionID]

    public init(
        id: Int,
        date: Date, 
        description: String, 
        postings: [RGSPosting],
        // transactionReferences: [EntryCompilerTransactionID] = []
    ) {
        self.id = id
        self.date = date
        self.description = description
        self.postings = postings
        // self.transactionReferences = transactionReferences
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
