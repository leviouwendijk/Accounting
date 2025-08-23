import Foundation

public struct EntryCompileDriver {
    public struct Result {
        public let entities: EntityStore
        public let accounts: AccountStore
        public let transactions: TransactionStore
        public let entries: [Entry]
        public let resolved: [ResolvedEntry]
    }

    public static func compile(projectRoot: URL,
                               rgsBase: [RGSAccount]) throws -> Result {
        let project = EntryCompilerProject(root: projectRoot)

        // 1) Settings → default timezone
        let settings = try EntryCompilerSettingsLoader.load(from: projectRoot)  // tz, etc.
        let defaultTZ = settings.entry.defaultTimezone

        // 2) Entities (already implemented)
        let entities = try EntityStoreLoader.load(from: project)

        // 3) Accounts (base in; overrides later)
        let accounts = try AccountStoreLoader.load(fromBase: rgsBase)

        // 4) Transactions (walk /transactions and parse)
        let transactions = try EntryCompilerTransactionsLoader.load(from: project)

        // 5) Entries (walk /entries and parse)
        let entries = try EntryCompilerEntriesLoader.load(from: project, defaultTZ: defaultTZ)

        // 6) Resolve entries → keys + tx refs
        let resolved = try entries.resolved(using: entities, accounts: accounts, transactions: transactions)

        // 7) Optional: basic DR/CR balance check
        try assertBalanced(resolved)

        return .init(entities: entities, accounts: accounts, transactions: transactions,
                     entries: entries, resolved: resolved)
    }

    @inline(__always)
    static func assertBalanced(_ entries: [ResolvedEntry]) throws {
        for e in entries {
            var sum: Decimal = 0
            for l in e.lines {
                sum += (l.direction == .debit ? +l.amount : -l.amount)
            }
            if sum != 0 {
                throw CompilingAssertionError.unbalanced(id: e.id, delta: sum)
            }
        }
    }
}
