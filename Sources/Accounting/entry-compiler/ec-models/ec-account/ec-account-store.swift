import Foundation

public struct AccountStore: Codable, Sendable {
    public let byCode: [String: RGSAccount]
    public init(_ accounts: [RGSAccount]) throws {
        var m: [String:RGSAccount] = [:]
        for a in accounts {
            if m.updateValue(a, forKey: a.code) != nil { throw AccountStoreError.duplicateCode(a.code) }
        }
        self.byCode = m
    }

    @inlinable
    public func resolve(_ ref: AccountRef) throws -> RGSAccount {
        switch ref {
        case .code(let s):
            if let acc = byCode[s] {
                return acc 
            }
            throw AccountStoreError.notFound(code: s)

        case .path(let segs):
            if let first = segs.first, let acc = byCode[first], first.allSatisfy(\.isNumber) {
                return acc
            }
            if segs.first == "account", let code = segs.dropFirst().first,
                code.allSatisfy(\.isNumber), let acc = byCode[code] {
                    return acc
            }
            throw AccountStoreError.invalidReference(path: segs)
        }
    }
}

public struct AccountStoreBuilder {
    private var map: [String: RGSAccount] = [:]   // authoritative (by code)

    public init() {}

    // Add a base set (e.g., RGS). Duplicates = error.
    public mutating func addBase(_ accounts: [RGSAccount]) throws {
        for a in accounts { 
            try add(a) 
        }
    }

    // Add a single fully-defined account. Duplicates = error.
    public mutating func add(_ account: RGSAccount) throws {
        if map[account.code] != nil { 
            throw AccountStoreError.duplicateCode(account.code) 
        }
        map[account.code] = account
    }

    // Optional: explicit replace (for project-level full overrides). Unknown = error.
    public mutating func replace(_ account: RGSAccount) throws {
        guard map[account.code] != nil else { 
            throw AccountStoreError.notFound(code: account.code) 
        }
        map[account.code] = account
    }

    // Optional: upsert (if you prefer last-write-wins). Comment out if you want stricter semantics.
    public mutating func upsert(_ account: RGSAccount) {
        map[account.code] = account
    }

    public func freeze() throws -> AccountStore {
        try AccountStore(Array(map.values))  // AccountStore init checks duplicates again
    }
}
