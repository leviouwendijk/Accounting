import Foundation

@inline(__always)
public func vprint(_ verbose: Bool, _ s: String) {
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
    public let loc_trace: Bool
    
    public init(
        entities: Bool = true,
        accounts: Bool = true,
        transactions: Bool = true,
        entries: Bool = true,
        assertion: Bool = true,
        loc_trace: Bool = true
    ) {
        self.entities = entities
        self.accounts = accounts
        self.transactions = transactions
        self.entries = entries
        self.assertion = assertion
        self.loc_trace = loc_trace
    }
    
    public var precondition: Bool {
        return (entities && accounts && transactions && entries)
    }
}

public struct EntryCompileDriver {
    public struct Result: Sendable {
        public let entities: EntityStore
        public let accounts: AccountStore
        public let transactions: TransactionStore
        public let entries: [Entry]
        public let resolved: [ResolvedEntry]
    }

    public static func compile(
        projectRoot: URL,
        setting: CompileDriveSetting = CompileDriveSetting(),
        verbose: Bool = false
    ) throws -> Result {
        vprint(verbose, "▶ Settings …")
        let project   = EntryCompilerProject(root: projectRoot)
        let settings  = try EntryCompilerSettingsLoader.load(
            from: projectRoot,
            trace: setting.loc_trace
        )
        let defaultTZ = settings.entry.defaultTimezone
        vprint(verbose, "  ✓ default timezone = \(defaultTZ.identifier)")

        var entities: EntityStore           = EntityStore([:])
        var accounts: AccountStore          = try AccountStore(nodes: [])
        var transactions: TransactionStore  = try TransactionStore([])
        var entries: [Entry]                = []
        var resolved: [ResolvedEntry]       = []

        if setting.entities {
            vprint(verbose, "▶ Entities …")
            entities = try EntityStoreLoader.load(
                from: project,
                settings: settings,
                verbose: verbose,
                trace: setting.loc_trace
            )
            vprint(verbose, "  ✓ \(entities.byFull.count) entities")
        }

        if setting.accounts {
            vprint(verbose, "▶ Accounts …")
            accounts = try AccountStoreLoader.load(
                from: project,
                settings: settings,
                verbose: verbose
            )
            vprint(verbose, "  ✓ \(accounts.count) accounts")
        }

        if setting.transactions {
            vprint(verbose, "▶ Transactions …")
            transactions = try EntryCompilerTransactionsLoader.load(
                from: project,
                verbose: verbose,
                trace: setting.loc_trace
            )
            vprint(verbose, "  ✓ \(transactions.count) transactions")
        }

        if setting.entries {
            vprint(verbose, "▶ Entries …")
            entries = try EntryCompilerEntriesLoader.load(
                from: project,
                settings: settings,
                allowCollisions: false,
                onCollision: nil,
                trace: setting.loc_trace,

                verbose: verbose,
            )
            vprint(verbose, "  ✓ \(entries.count) entries")
        }

        if setting.precondition {
            vprint(verbose, "▶ Resolving …")
            resolved = try entries.resolved(
                using: entities,
                accounts: accounts,
                transactions: transactions,
                settings: settings
            )
            vprint(verbose, "  ✓ \(resolved.count) resolved entries")
        }

        if setting.assertion {
            guard setting.precondition else {
                throw CompileDriverError.invalidSettings(
                    "`assertion` requires entities+accounts+transactions+entries to be enabled"
                )
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
            try e.assertBalancing()
        }
    }
}

extension EntryCompileDriver {
    // async overload for parallel perf
    public static func compile(
        projectRoot: URL,
        setting: CompileDriveSetting = CompileDriveSetting(),
        verbose: Bool = false
    ) async throws -> Result {
        vprint(verbose, "▶ Settings …")
        let project   = EntryCompilerProject(root: projectRoot)
        // can use async variant, but sync is fine here too
        let settings  = try EntryCompilerSettingsLoader.load(
            from: projectRoot,
            trace: setting.loc_trace
        )
        let defaultTZ = settings.entry.defaultTimezone
        vprint(verbose, "  ✓ default timezone = \(defaultTZ.identifier)")

        var entities: EntityStore           = EntityStore([:])
        var accounts: AccountStore          = try AccountStore(nodes: [])
        var transactions: TransactionStore  = try TransactionStore([])
        var entries: [Entry]                = []
        var resolved: [ResolvedEntry]       = []

        if setting.entities {
            vprint(verbose, "▶ Entities …")
            entities = try await EntityStoreLoader.load(
                from: project,
                settings: settings,
                verbose: verbose,
                trace: setting.loc_trace,
            )
            vprint(verbose, "  ✓ \(entities.byFull.count) entities")
        }

        if setting.accounts {
            vprint(verbose, "▶ Accounts …")
            // async AccountStoreLoader just forwards to sync, but gives you a consistent await call
            accounts = try AccountStoreLoader.load(
                from: project,
                settings: settings,
                verbose: verbose
            )
            vprint(verbose, "  ✓ \(accounts.count) accounts")
        }

        if setting.transactions {
            vprint(verbose, "▶ Transactions …")
            transactions = try await EntryCompilerTransactionsLoader.load(
                from: project,
                verbose: verbose,
                trace: setting.loc_trace
            )
            vprint(verbose, "  ✓ \(transactions.count) transactions")
        }

        if setting.entries {
            vprint(verbose, "▶ Entries …")
            entries = try await EntryCompilerEntriesLoader.load(
                from: project,
                settings: settings,
                allowCollisions: false,
                onCollision: nil,
                trace: setting.loc_trace,

                verbose: verbose
            )
            vprint(verbose, "  ✓ \(entries.count) entries")
        }

        if setting.precondition {
            vprint(verbose, "▶ Resolving …")
            resolved = try entries.resolved(
                using: entities,
                accounts: accounts,
                transactions: transactions,
                settings: settings
            )
            vprint(verbose, "  ✓ \(resolved.count) resolved entries")
        }

        if setting.assertion {
            guard setting.precondition else {
                throw CompileDriverError.invalidSettings(
                    "`assertion` requires entities+accounts+transactions+entries to be enabled"
                )
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
}
