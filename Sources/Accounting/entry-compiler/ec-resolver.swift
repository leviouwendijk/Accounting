import Foundation

public protocol SQLDatabase: Sendable {
    func query<T>(_ sql: String, binds: [Encodable]) throws -> T
}

public struct Resolver: Sendable {
    public let db: SQLDatabase
    public init(db: SQLDatabase) { self.db = db }
    public func entityID(for path: EntityPath) throws -> Int {
        throw NSError(domain: "Resolver", code: 0, userInfo: [NSLocalizedDescriptionKey:"not implemented"])
    }
    public func accountID(for path: AccountPath) throws -> Int {
        throw NSError(domain: "Resolver", code: 0, userInfo: [NSLocalizedDescriptionKey:"not implemented"])
    }
}
