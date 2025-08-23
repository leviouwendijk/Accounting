import Foundation

@inline(__always)
func vprint(_ verbose: Bool, _ s: String) {
    guard verbose else { return }
    FileHandle.standardError.write(Data((s + "\n").utf8))
}

public struct EntryCompileDriver {
    public struct Result {
        public let entities: EntityStore
        public let accounts: AccountStore
        public let transactions: TransactionStore
        public let entries: [Entry]
        public let resolved: [ResolvedEntry]
    }

    // public static func compile(
    //     projectRoot: URL,
    //     verbose: Bool = false,
    //     log: (String) -> Void = { _ in }     // pass { print($0) } from CLI
    // ) throws -> Result {
    //     @inline(__always) func L(_ s: String) { if verbose { log(s) } }

    //     L("▶ Settings …")
    //     let project   = EntryCompilerProject(root: projectRoot)
    //     let settings  = try EntryCompilerSettingsLoader.load(from: projectRoot)
    //     let defaultTZ = settings.entry.defaultTimezone
    //     L("  ✓ default timezone = \(defaultTZ.identifier)")

    //     L("▶ Entities …")
    //     let entities     = try EntityStoreLoader.load(from: project)
    //     L("  ✓ \(entities.count) entities")

    //     L("▶ Accounts …")
    //     let accounts     = try AccountStoreLoader.load(from: project)
    //     L("  ✓ \(accounts.count) accounts")

    //     L("▶ Transactions …")
    //     let transactions = try EntryCompilerTransactionsLoader.load(from: project)
    //     L("  ✓ \(transactions.count) transactions")

    //     L("▶ Entries …")
    //     let entries      = try EntryCompilerEntriesLoader.load(from: project, defaultTZ: defaultTZ)
    //     L("  ✓ \(entries.count) entries")

    //     L("▶ Resolving …")
    //     let resolved = try entries.resolved(using: entities, accounts: accounts, transactions: transactions)
    //     L("  ✓ \(resolved.count) resolved entries")

    //     L("▶ Trial balance …")
    //     try assertBalanced(resolved)
    //     L("  ✓ balanced")

    //     return .init(entities: entities, accounts: accounts, transactions: transactions, entries: entries, resolved: resolved)
    // }

    public static func compile(projectRoot: URL, verbose: Bool = false) throws -> Result {
        vprint(verbose, "▶ Settings …")
        let project   = EntryCompilerProject(root: projectRoot)
        let settings  = try EntryCompilerSettingsLoader.load(from: projectRoot)
        let defaultTZ = settings.entry.defaultTimezone
        vprint(verbose, "  ✓ default timezone = \(defaultTZ.identifier)")

        vprint(verbose, "▶ Entities …")
        let entities = try EntityStoreLoader.load(from: project, verbose: verbose)

        vprint(verbose, "▶ Accounts …")
        let accounts = try AccountStoreLoader.load(from: project)

        vprint(verbose, "▶ Transactions …")
        let transactions = try EntryCompilerTransactionsLoader.load(from: project)

        vprint(verbose, "▶ Entries …")
        let entries = try EntryCompilerEntriesLoader.load(from: project, defaultTZ: defaultTZ)

        vprint(verbose, "▶ Resolve & assert …")
        let resolved = try entries.resolved(using: entities, accounts: accounts, transactions: transactions)
        try assertBalanced(resolved)
        vprint(verbose, "  ✓ balanced")

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
