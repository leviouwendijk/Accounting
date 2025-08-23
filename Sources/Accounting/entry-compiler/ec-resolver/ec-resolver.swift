import Foundation

public protocol SQLDatabase: Sendable {
    func query<T>(_ sql: String, binds: [Encodable]) throws -> T
}

public struct GenericResolver: Sendable {
    public let db: SQLDatabase
    public init(db: SQLDatabase) { self.db = db }

    public func entityID(for path: EntityKey) throws -> Int {
        throw EntryCompilerResolverError.notImplemented
    }

    public func accountID(for key: AccountKey) throws -> Int {
        throw EntryCompilerResolverError.notImplemented
    }
}
