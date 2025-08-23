import Foundation

@inline(__always)
func vprint(_ verbose: Bool, _ s: String) {
    guard verbose else { return }
    FileHandle.standardError.write(Data((s + "\n").utf8))
}

public enum CompileDriverError: Error, CustomStringConvertible {
    case invalidSettings(String)
    public var description: String {
        switch self {
        case .invalidSettings(let s): return s
        }
    }
}

public struct CompileDriveSetting {
    public let entities: Bool
    public let accounts: Bool
    public let transactions: Bool
    public let entries: Bool
    public let assertion: Bool
    
    public init(
        entities: Bool = true,
        accounts: Bool = true,
        transactions: Bool = true,
        entries: Bool = true,
        assertion: Bool = true
    ) {
        self.entities = entities
        self.accounts = accounts
        self.transactions = transactions
        self.entries = entries
        self.assertion = assertion
    }
    
    public var precondition: Bool {
        return (entities && accounts && transactions && entries)
    }
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

    public static func compile(
        projectRoot: URL,
        setting: CompileDriveSetting = CompileDriveSetting(),
        verbose: Bool = false
    ) throws -> Result {
        vprint(verbose, "▶ Settings …")
        let project   = EntryCompilerProject(root: projectRoot)
        let settings  = try EntryCompilerSettingsLoader.load(from: projectRoot)
        let defaultTZ = settings.entry.defaultTimezone
        vprint(verbose, "  ✓ default timezone = \(defaultTZ.identifier)")

        var entities: EntityStore       = EntityStore([:])
        var accounts: AccountStore      = try AccountStore([])
        var transactions: TransactionStore = try TransactionStore([])
        var entries: [Entry]            = []
        var resolved: [ResolvedEntry]   = []

        if setting.entities {
            vprint(verbose, "▶ Entities …")
            entities = try EntityStoreLoader.load(from: project, defaultTZ: defaultTZ, verbose: verbose)
            vprint(verbose, "  ✓ \(entities.byFull.count) entities")
        }

        if setting.accounts {
            vprint(verbose, "▶ Accounts …")
            accounts = try AccountStoreLoader.load(from: project, defaultTZ: defaultTZ, verbose: verbose)
            vprint(verbose, "  ✓ \(accounts.count) accounts")
        }

        if setting.transactions {
            vprint(verbose, "▶ Transactions …")
            transactions = try EntryCompilerTransactionsLoader.load(from: project)
            vprint(verbose, "  ✓ \(transactions.count) transactions")
        }

        if setting.entries {
            vprint(verbose, "▶ Entries …")
            entries = try EntryCompilerEntriesLoader.load(from: project, defaultTZ: defaultTZ)
            vprint(verbose, "  ✓ \(entries.count) entries")
        }

        if setting.precondition {
            vprint(verbose, "▶ Resolving …")
            resolved = try entries.resolved(using: entities, accounts: accounts, transactions: transactions) // :contentReference[oaicite:7]{index=7}
            vprint(verbose, "  ✓ \(resolved.count) resolved entries")
        }

        if setting.assertion {
            guard setting.precondition else {
                throw CompileDriverError.invalidSettings("`assertion` requires entities+accounts+transactions+entries to be enabled")
            }
            vprint(verbose, "▶ Trial balance …")
            try assertBalanced(resolved)
            vprint(verbose, "  ✓ balanced")
        }

        return .init(
            entities: entities,
            accounts: accounts,
            transactions: transactions,
            entries: entries,
            resolved: resolved
        )
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
