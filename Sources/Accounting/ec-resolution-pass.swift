import Foundation
import Position

public enum EntryResolutionPass {
    public static func resolve(
        _ entries: [Entry],
        entities: EntityStore,
        accounts: AccountStore,
        transactions: TransactionStore,
        settings: EntryCompilerSettings
    ) throws -> [ResolvedEntry] {
        // Keep your depreciation prepass
        let entitiesResolved = try DepreciationResolutionPass.run(on: entities, using: accounts)

        var out: [ResolvedEntry] = []
        out.reserveCapacity(entries.count)

        for e in entries {
            do {
                let lines: [ResolvedLine] = try e.lines.map { l in
                    // ensure we ALWAYS pass a location (line → entry fallback)
                    let loc = l.location ?? e.location

                    let eDef = try entitiesResolved.resolve(l.entity, at: loc)

                    // AccountStore.resolve returns node; use canonical posting code
                    let node = try accounts.resolve(l.account, at: loc)

                    try validateEntityAccountIntersection(
                        entity: eDef,
                        account: node,
                        at: loc
                    )
                    let postingCode = node.codes.code

                    return ResolvedLine(
                        entity: eDef.key,
                        account: AccountKey(postingCode),
                        direction: l.direction,
                        amount: l.amount,
                        adjustment: l.adjustment
                    )
                }

                let txKeys = try transactions.resolveAll(ids: e.transactionReferences, at: e.location)
                let resolvedDate = try e.date.resolved(for: e, using: settings)

                out.append(
                    ResolvedEntry(
                        id: e.id,
                        date: resolvedDate,
                        lines: lines,
                        details: e.details,
                        timezone: e.timezone,
                        metadata: e.metadata,
                        transactionReferences: txKeys,
                        vat: e.vat,
                        location: e.location,
                        mistake: e.mistake,
                        select: e.select,
                        verbose: e.verbose
                    )
                )
            } catch {
                // ← add entry id + entry-level location to whatever blew up (ambiguous alias, unknown account, etc.)
                throw ResolutionContextError(entryID: e.id, location: e.location, underlying: error)
            }
        }

        return out
    }
}

public extension Array where Element == Entry {
    func resolved(
        using entities: EntityStore,
        accounts: AccountStore,        // node-backed
        transactions: TransactionStore,
        settings: EntryCompilerSettings
    ) throws -> [ResolvedEntry] {
        try EntryResolutionPass.resolve(
            self,
            entities: entities,
            accounts: accounts,
            transactions: transactions,
            settings: settings
        )
    }
}

// helpers for validation

private enum LiquidEntityKind {
    case balance
    case cash
}

private enum LiquidAccountKind {
    case bank
    case cash
}

@inline(__always)
private func liquidEntityKind(
    from entity: EntityDef
) -> LiquidEntityKind? {
    guard entity.key.class == "liquids" else {
        return nil
    }

    switch entity.key.family {
    case "balance":
        return .balance

    case "cash":
        return .cash

    default:
        return nil
    }
}

@inline(__always)
private func liquidAccountKind(
    from node: RGSNode
) -> LiquidAccountKind? {
    let code = node.codes.code

    if code.hasPrefix("BLimBan") {
        return .bank
    }

    if code.hasPrefix("BLimKas") {
        return .cash
    }

    return nil
}

@inline(__always)
private func validateEntityAccountIntersection(
    entity: EntityDef,
    account node: RGSNode,
    at loc: Position?
) throws {
    guard
        let entityKind = liquidEntityKind(from: entity),
        let accountKind = liquidAccountKind(from: node)
    else {
        return
    }

    switch (entityKind, accountKind) {
    case (.balance, .bank):
        return

    case (.cash, .cash):
        return

    case (.cash, .bank):
        throw EntryCompilerResolverError.incompatibleEntityAccount(
            entity: entity.key.identifier(displaying: .fullchain),
            account: node.codes.code,
            reason: "cash entities only belong on BLimKas* accounts, not BLimBan* accounts",
            at: loc
        )

    case (.balance, .cash):
        throw EntryCompilerResolverError.incompatibleEntityAccount(
            entity: entity.key.identifier(displaying: .fullchain),
            account: node.codes.code,
            reason: "balance entities only belong on BLimBan* accounts, not BLimKas* accounts",
            at: loc
        )
    }
}
