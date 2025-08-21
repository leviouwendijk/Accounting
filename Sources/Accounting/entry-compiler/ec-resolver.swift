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
    public func accountID(for path: AccountPath) throws -> Int {
        throw EntryCompilerResolverError.notImplemented
    }
}

public extension Array where Element == Entry {
    func resolved(using store: EntityStore) throws -> [ResolvedEntry] {
        try self.map { e in
            let rLines: [ResolvedLine] = try e.lines.map { l in
                let def = try store.resolve(l.entity)
                return ResolvedLine(
                    entity: def.key,
                    account: l.account,
                    direction: l.direction,
                    amount: l.amount,
                    adjustment: l.adjustment
                )
            }
            return ResolvedEntry(
                id: e.id,
                date: e.date,
                lines: rLines,
                details: e.details,
                timezone: e.timezone,
                transactionReferences: e.transactionReferences
            )
        }
    }
}
