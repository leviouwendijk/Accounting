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

// public struct AccountStoreBuilder {
//     private var map: [String: RGSAccount] = [:]   // authoritative (by code)

//     public init() {}

//     // Add a base set (e.g., RGS). Duplicates = error.
//     public mutating func addBase(_ accounts: [RGSAccount]) throws {
//         for a in accounts { 
//             try add(a) 
//         }
//     }

//     // Add a single fully-defined account. Duplicates = error.
//     public mutating func add(_ account: RGSAccount) throws {
//         if map[account.code] != nil { 
//             throw AccountStoreError.duplicateCode(account.code) 
//         }
//         map[account.code] = account
//     }

//     // Optional: explicit replace (for project-level full overrides). Unknown = error.
//     public mutating func replace(_ account: RGSAccount) throws {
//         guard map[account.code] != nil else { 
//             throw AccountStoreError.notFound(code: account.code) 
//         }
//         map[account.code] = account
//     }

//     // Optional: upsert (if you prefer last-write-wins). Comment out if you want stricter semantics.
//     public mutating func upsert(_ account: RGSAccount) {
//         map[account.code] = account
//     }

//     public func freeze() throws -> AccountStore {
//         try AccountStore(Array(map.values))  // AccountStore init checks duplicates again
//     }
// }

public struct AccountStoreBuilder {
    private var base: [String: RGSAccount] = [:]
    private var overrides: [String: AccountDef] = [:]

    public init() {}

    public mutating func addBase(_ accounts: [RGSAccount]) throws {
        for a in accounts {
            if base.updateValue(a, forKey: a.code) != nil {
                throw AccountStoreError.duplicateCode(a.code)
            }
        }
    }

    public mutating func addOverride(_ def: AccountDef) {
        overrides[def.code] = def
    }

    public mutating func addOverrides(_ defs: [AccountDef]) throws {
        for d in defs { addOverride(d) }
    }

    public func freeze() throws -> AccountStore {
        var out = base

        for (code, ov) in overrides {
            if var b = out[code] {
                if let lbl = ov.label      { b = RGSAccount(code: b.code, label: lbl, level: b.level, direction: b.direction, identifiers: b.identifiers, applicability: b.applicability) }
                if let dir = ov.direction  { b = RGSAccount(code: b.code, label: b.label, level: b.level, direction: dir,     identifiers: b.identifiers, applicability: b.applicability) }
                if let lvl = ov.level      { b = RGSAccount(code: b.code, label: b.label, level: lvl,     direction: b.direction, identifiers: b.identifiers, applicability: b.applicability) }
                if let ids = ov.identifiers{ b = RGSAccount(code: b.code, label: b.label, level: b.level, direction: b.direction, identifiers: ids, applicability: b.applicability) }
                if let app = ov.applicability { b = RGSAccount(code: b.code, label: b.label, level: b.level, direction: b.direction, identifiers: b.identifiers, applicability: app) }
                out[code] = b
            } else {
                guard
                    let lbl = ov.label,
                    let dir = ov.direction,
                    let lvl = ov.level
                else {
                    throw AccountStoreError.missingRequiredForNewAccount(
                        code: code,
                        missing: ["label": ov.label == nil, "direction": ov.direction == nil, "level": ov.level == nil]
                        .compactMap { $0.value ? $0.key : nil }.joined(separator: ", ")
                    )
                }
                let ids = ov.identifiers ?? RGSIdentifiers(rgs: code, omslag: nil)
                let app = ov.applicability ?? Applicability(zzp: "", ez: "", bv: "", svc: "", branche: "")
                out[code] = RGSAccount(code: code, label: lbl, level: lvl, direction: dir, identifiers: ids, applicability: app)
            }
        }

        return try AccountStore(Array(out.values))
    }
}
