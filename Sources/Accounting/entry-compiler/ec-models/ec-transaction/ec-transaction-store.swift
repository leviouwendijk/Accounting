import Foundation

public struct TransactionStore: Codable, Sendable {
    public let byID: [TransactionKey: Transaction]

    public init(_ txs: [Transaction]) throws {
        var m: [TransactionKey: Transaction] = [:]
        for t in txs {
            guard let id = t.id else { 
                continue 
            }
            let k = TransactionKey(id)
            if m.updateValue(t, forKey: k) != nil { throw TransactionStoreError.duplicateID(id) }
        }
        self.byID = m
    }

    @inlinable
    public func resolve(id: Int) throws -> Transaction {
        guard let t = byID[TransactionKey(id)] else { throw TransactionStoreError.notFound(id: id) }
        return t
    }

    @inlinable
    public func resolveAll(ids: [Int]) throws -> [TransactionKey] {
        try ids.map { i in
            guard byID[TransactionKey(i)] != nil else { throw TransactionStoreError.notFound(id: i) }
            return TransactionKey(i)
        }
    }
}

public struct TransactionStoreBuilder {
    private var map: [TransactionKey: Transaction] = [:]
    public init() {}

    public mutating func add(_ t: Transaction) throws {
        guard let id = t.id else { return }
        let k = TransactionKey(id)
        if map[k] != nil { throw TransactionStoreError.duplicateID(id) }
        map[k] = t
    }

    public mutating func addAll(_ ts: [Transaction]) throws {
        for t in ts { try add(t) }
    }

    public func freeze() throws -> TransactionStore { try TransactionStore(Array(map.values)) }
}
