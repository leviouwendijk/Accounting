import Foundation

public struct JournalEntry {
    public let id: String
    public let date: Date
    public let description: String
    public var postings: [Posting]

    public init(
        id: String, 
        date: Date, 
        description: String, 
        postings: [Posting]
    ) {
        self.id = id
        self.date = date
        self.description = description
        self.postings = postings
    }
}

public struct Posting {
    public let account: Account
    public let entity: Entity?
    public let amount: Double
    public let mutation: Direction

    public init(
        account: Account, 
        entity: Entity?, 
        amount: Double, 
        mutation: Direction
    ) {
        self.account = account
        self.entity = entity
        self.amount = amount
        self.mutation = mutation
    }
}
