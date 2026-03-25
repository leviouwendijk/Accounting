import Foundation

// public enum EntryResolutionPass {
//     public static func resolve(
//         _ entries: [Entry],
//         entities: EntityStore,
//         accounts: AccountStore,        // node-backed
//         transactions: TransactionStore,
//         settings: EntryCompilerSettings
//     ) throws -> [ResolvedEntry] {
//         // addition replacing entities line below
//         let entitiesResolved = try DepreciationResolutionPass.run(on: entities, using: accounts)

//         return try entries.map { e in
//             let lines = try e.lines.map { l in
//                 // let eDef = try entities.resolve(l.entity, at: l.location)
//                 let eDef = try entitiesResolved.resolve(l.entity, at: l.location)

//                 // AccountStore.resolve now returns RGSNode
//                 let node = try accounts.resolve(l.account, at: l.location)
//                 let postingCode = node.codes.code   // <- canonical posting code from the node

//                 return ResolvedLine(
//                     entity: eDef.key,
//                     account: AccountKey(postingCode),
//                     direction: l.direction,
//                     amount: l.amount,
//                     adjustment: l.adjustment
//                 )
//             }

//             let txKeys = try transactions.resolveAll(
//                 ids: e.transactionReferences,
//                 at: e.location
//             )

//             // let tz = (e.timezone.flatMap(TimeZone.init(identifier:))) ?? settings.entry.defaultTimezone
//             let resolved = try e.date.resolved(for: e, using: settings)

//             return ResolvedEntry(
//                 id: e.id,
//                 date: resolved,
//                 lines: lines,
//                 details: e.details,
//                 timezone: e.timezone,
//                 metadata: e.metadata,
//                 transactionReferences: txKeys
//             )
//         }
//     }
// }

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

                // out.append(
                //     ResolvedEntry(
                //         id: e.id,
                //         date: resolvedDate,
                //         lines: lines,
                //         details: e.details,
                //         timezone: e.timezone,
                //         metadata: e.metadata,
                //         transactionReferences: txKeys
                //     )
                // )
                out.append(
                    ResolvedEntry(
                        id: e.id,
                        date: resolvedDate,
                        lines: lines,
                        details: e.details,
                        timezone: e.timezone,
                        metadata: e.metadata,
                        transactionReferences: txKeys,
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
