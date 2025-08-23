import Foundation

public struct EntryCompileDriver {
    public struct Result {
        public let entities: EntityStore
        public let accounts: AccountStore
        public let transactions: TransactionStore
        public let entries: [Entry]
        public let resolved: [ResolvedEntry]
    }

    public static func compile(projectRoot: URL) throws -> Result {
        let project   = EntryCompilerProject(root: projectRoot)
        let settings  = try EntryCompilerSettingsLoader.load(from: projectRoot)
        let defaultTZ = settings.entry.defaultTimezone

        let entities     = try EntityStoreLoader.load(from: project)
        let accounts     = try AccountStoreLoader.load(from: project)
        let transactions = try EntryCompilerTransactionsLoader.load(from: project)
        let entries      = try EntryCompilerEntriesLoader.load(from: project, defaultTZ: defaultTZ)

        let resolved = try entries.resolved(using: entities, accounts: accounts, transactions: transactions)
        try assertBalanced(resolved)
        return .init(entities: entities, accounts: accounts, transactions: transactions, entries: entries, resolved: resolved)
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
