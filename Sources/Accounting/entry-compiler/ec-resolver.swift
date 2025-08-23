import Foundation

public enum EntryCompilerResolverError: Error, LocalizedError {
    case notImplemented
}

public protocol SQLDatabase: Sendable {
    func query<T>(_ sql: String, binds: [Encodable]) throws -> T
}

public struct Resolver: Sendable {
    public let db: SQLDatabase
    public init(db: SQLDatabase) { self.db = db }

    public func entityID(for path: EntityKey) throws -> Int {
        throw EntryCompilerResolverError.notImplemented
    }

    public func accountID(for key: AccountKey) throws -> Int {
        throw EntryCompilerResolverError.notImplemented
    }
}

public enum EntryResolutionPass {
    public static func resolve(
        _ entries: [Entry],
        entities: EntityStore,
        accounts: AccountStore
    ) throws -> [ResolvedEntry] {
        try entries.map { e in
            let lines = try e.lines.map { l in
                let eDef = try entities.resolve(l.entity)   // EntityRef → EntityDef
                let aDef = try accounts.resolve(l.account)  // AccountRef → RGSAccount
                return ResolvedLine(
                    entity: eDef.key,
                    account: AccountKey(aDef.code),         // canonicalize to code
                    direction: l.direction,
                    amount: l.amount,
                    adjustment: l.adjustment
                )
            }
            return ResolvedEntry(
                id: e.id, 
                date: e.date,
                lines: lines,
                details: e.details,
                timezone: e.timezone,
                transactionReferences: e.transactionReferences
            )
        }
    }
}

public extension Array where Element == Entry {
    func resolved(using entities: EntityStore, accounts: AccountStore) throws -> [ResolvedEntry] {
        try EntryResolutionPass.resolve(self, entities: entities, accounts: accounts)
    }
}
