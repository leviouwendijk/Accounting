import Foundation

@inlinable
public func latestEntryID(in entries: [Entry]) -> Int? {
    entries.compactMap { $0.id }.max()
}

@inlinable
public func latestTransactionID(in txs: [Transaction]) -> Int? {
    txs.compactMap { $0.id }.max()
}

public enum IDKind: String, Sendable {
    case entry, transaction
}

public enum IDScanner: Sendable {
    public static func suggestNextEntryID(
        project: EntryCompilerProject,
        settings: EntryCompilerSettings,
        allowCollisions: Bool = true,
    ) throws -> Int {
        let entries = try EntryCompilerEntriesLoader.load(from: project, settings: settings, allowCollisions: allowCollisions)
        let latest = latestEntryID(in: entries) ?? 0
        return latest + 1
    }

    public static func suggestNextTransactionID(
        project: EntryCompilerProject,
        verbose: Bool = false
    ) throws -> Int {
        let store = try EntryCompilerTransactionsLoader.load(from: project, verbose: verbose)
        let latest = store.byID.keys.map(\.id).max() ?? 0
        return latest + 1
    }

    public static func usedIDs(
        project: EntryCompilerProject,
        settings: EntryCompilerSettings,
        kind: IDKind,
        allowCollisions: Bool = false,
        verbose: Bool = false
    ) throws -> [Int] {
        switch kind {
        case .entry:
            let entries = try EntryCompilerEntriesLoader.load(from: project, settings: settings, allowCollisions: allowCollisions) // scans entries/*.ec
            return Array(Set(entries.compactMap { $0.id })).sorted()
        case .transaction:
            let store = try EntryCompilerTransactionsLoader.load(from: project, verbose: verbose) // scans transactions/*.ec
            return Array(Set(store.byID.keys.map(\.id))).sorted()
        }
    }

    @inlinable
    public static func compressRuns(_ ids: [Int]) -> [ClosedRange<Int>] {
        let s = Array(Set(ids)).sorted()
        guard let first = s.first else { return [] }

        var out: [ClosedRange<Int>] = []
        var start = first
        var prev  = first

        for n in s.dropFirst() {
            if n == prev + 1 {
                prev = n
            } else {
                out.append(start...prev)
                start = n
                prev  = n
            }
        }
        out.append(start...prev)
        return out
    }

    @inlinable
    public static func gaps(between ids: [Int]) -> [ClosedRange<Int>] {
        let s = Array(Set(ids)).sorted()
        guard s.count >= 2 else { return [] }
        var out: [ClosedRange<Int>] = []
        for (a, b) in zip(s, s.dropFirst()) {
            if b > a + 1 { out.append((a + 1)...(b - 1)) }
        }
        return out
    }

    public static func string(_ ranges: [ClosedRange<Int>]) -> String {
        ranges.map { r in
            (r.lowerBound == r.upperBound) ? "\(r.lowerBound)" : "\(r.lowerBound)–\(r.upperBound)"
        }.joined(separator: ", ")
    }
}
