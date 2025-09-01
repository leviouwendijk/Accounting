import Foundation

public enum IDKind: String, Sendable {
    case entry, transaction
}

public enum IDScanner: Sendable {
    // Latest IDs
    @inlinable
    public static func latestEntryID(in entries: [Entry]) -> Int? {
        entries.compactMap { $0.id }.max()
    }

    @inlinable
    public static func latestTransactionID(in txs: [Transaction]) -> Int? {
        txs.compactMap { $0.id }.max()
    }

    // Project-wired suggestions
    public static func suggestNextEntryID(
        project: EntryCompilerProject,
        settings: EntryCompilerSettings
    ) throws -> Int {
        let entries = try EntryCompilerEntriesLoader.load(from: project, settings: settings) // scans entries/*.ec
        let latest = latestEntryID(in: entries) ?? 0
        return latest + 1
    }

    public static func suggestNextTransactionID(
        project: EntryCompilerProject,
        verbose: Bool = false
    ) throws -> Int {
        let store = try EntryCompilerTransactionsLoader.load(from: project, verbose: verbose)
        let latest = latestTransactionID(in: store.all) ?? 0
        return latest + 1
    }
}
