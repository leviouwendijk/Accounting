import Foundation

public enum EntryResolutionPass {
    public static func resolve(
        _ entries: [Entry],
        entities: EntityStore,
        accounts: AccountStore,        // node-backed
        transactions: TransactionStore,
        settings: EntryCompilerSettings
    ) throws -> [ResolvedEntry] {
        try entries.map { e in
            let lines = try e.lines.map { l in
                let eDef = try entities.resolve(l.entity, at: l.location)

                // AccountStore.resolve now returns RGSNode
                let node = try accounts.resolve(l.account, at: l.location)
                let postingCode = node.codes.code   // <- canonical posting code from the node

                return ResolvedLine(
                    entity: eDef.key,
                    account: AccountKey(postingCode),
                    direction: l.direction,
                    amount: l.amount,
                    adjustment: l.adjustment
                )
            }

            let txKeys = try transactions.resolveAll(
                ids: e.transactionReferences,
                at: e.location
            )

            // let tz = (e.timezone.flatMap(TimeZone.init(identifier:))) ?? settings.entry.defaultTimezone
            let resolved = try e.date.resolved(for: e, using: settings)

            return ResolvedEntry(
                id: e.id,
                date: resolved,
                lines: lines,
                details: e.details,
                timezone: e.timezone,
                metadata: e.metadata,
                transactionReferences: txKeys
            )
        }
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
