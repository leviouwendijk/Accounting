import Foundation

public struct TrialBalanceRow: Codable, Sendable {
    public let accountCode: String
    public let debit: Decimal
    public let credit: Decimal
    public let entityId: Int? 
    public var net: Decimal { debit - credit }
}

public func trialBalance(_ entries: [ResolvedEntry]) -> [TrialBalanceRow] {
    var deb: [String: Decimal] = [:]
    var cre: [String: Decimal] = [:]
    for e in entries {
        for l in e.lines {
            let code = l.account.code
            if l.direction == .debit {
                deb[code, default: 0] += l.amount
            } else {
                cre[code, default: 0] += l.amount
            }
        }
    }
    let codes = Set(deb.keys).union(cre.keys).sorted()
    return codes.map { c in
        TrialBalanceRow(
            accountCode: c,
            debit: deb[c] ?? 0,
            credit: cre[c] ?? 0,
            entityId: nil
        )
    }
}

public func trialBalance(
    _ entries: [ResolvedEntry],
    entityId: (EntityKey) -> Int?
) -> [TrialBalanceRow] {
    struct Key: Hashable { let code: String; let eid: Int? }
    var deb: [Key: Decimal] = [:]
    var cre: [Key: Decimal] = [:]

    for e in entries {
        for l in e.lines {
            let code = l.account.code
            let eid  = entityId(l.entity)
            let k    = Key(code: code, eid: eid)

            if l.direction == .debit { 
                deb[k, default: 0] += l.amount 
            } else { 
                cre[k, default: 0] += l.amount 
            }
        }
    }

    let keys = Set(deb.keys).union(cre.keys).sorted { ($0.code,$0.eid ?? -1) < ($1.code,$1.eid ?? -1) }
    return keys.map { k in
        TrialBalanceRow(
            accountCode: k.code,
            debit: deb[k] ?? 0,
            credit: cre[k] ?? 0,
            entityId: k.eid
        )
    }
}
