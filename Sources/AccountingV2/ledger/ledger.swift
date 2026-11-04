import Foundation
import Primitives

/// One financial contribution derived from an existing journal line.
/// The journal remains the authoritative record.
public struct Posting: Invariant, Sendable {
    /// Source coordinates are meaningful within the owning Ledger.
    /// They are not globally unique identifiers.
    public struct Source: Hashable, Sendable {
        public let entryID: Entry.ID
        public let entryIndex: Int
        public let lineIndex: Int

        fileprivate init(entryID: Entry.ID, entryIndex: Int, lineIndex: Int) {
            self.entryID = entryID
            self.entryIndex = entryIndex
            self.lineIndex = lineIndex
        }
    }

    public struct Raw: Sendable {
        public let journal: Journal
        public let entryIndex: Int
        public let lineIndex: Int

        public init(journal: Journal, entryIndex: Int, lineIndex: Int) {
            self.journal = journal
            self.entryIndex = entryIndex
            self.lineIndex = lineIndex
        }
    }

    public enum Error: Swift.Error, Equatable, Sendable {
        case invalidEntryIndex(Int)
        case invalidLineIndex(entry: Entry.ID, index: Int)
    }

    public let source: Source
    public let date: Date
    public let line: Entry.Line

    public init(_ raw: Raw) throws(Error) {
        guard raw.journal.entries.indices.contains(raw.entryIndex) else {
            throw .invalidEntryIndex(raw.entryIndex)
        }
        let entry = raw.journal.entries[raw.entryIndex]
        guard entry.lines.indices.contains(raw.lineIndex) else {
            throw .invalidLineIndex(entry: entry.id, index: raw.lineIndex)
        }

        self.source = Source(
            entryID: entry.id,
            entryIndex: raw.entryIndex,
            lineIndex: raw.lineIndex
        )
        self.date = entry.date
        self.line = entry.lines[raw.lineIndex]
    }

    public var account: Account.Reference {
        line.account
    }

    public var entity: Entity.Reference {
        line.entity
    }

    public var direction: Direction {
        line.direction
    }

    public var amount: Decimal {
        line.amount
    }

    public var signedAmount: Decimal {
        line.signedAmount
    }
}

/// The immutable projection of an authoritative Journal into financial postings.
/// The original Journal is retained, and every posting has an original source.
public struct Ledger: Invariant, Sendable {
    public struct Raw: Sendable {
        public let journal: Journal

        public init(journal: Journal) {
            self.journal = journal
        }
    }

    public enum Error: Swift.Error, Equatable, Sendable {
        case invalidPosting(Posting.Error)
    }

    public let journal: Journal
    public let postings: [Posting]

    private let offsetsByEntry: [Entry.ID: [Int]]
    private let offsetsByAccount: [Account.Reference: [Int]]
    private let offsetsByEntity: [Entity.Reference: [Int]]

    public init(_ raw: Raw) throws(Error) {
        var postings: [Posting] = []
        postings.reserveCapacity(
            raw.journal.entries.reduce(0) { $0 + $1.lines.count }
        )

        var byEntry: [Entry.ID: [Int]] = [:]
        var byAccount: [Account.Reference: [Int]] = [:]
        var byEntity: [Entity.Reference: [Int]] = [:]

        for (entryIndex, entry) in raw.journal.entries.enumerated() {
            for lineIndex in entry.lines.indices {
                let posting: Posting
                do {
                    posting = try Posting(.init(
                        journal: raw.journal,
                        entryIndex: entryIndex,
                        lineIndex: lineIndex
                    ))
                } catch {
                    throw .invalidPosting(error)
                }

                let offset = postings.count
                postings.append(posting)
                byEntry[entry.id, default: []].append(offset)
                byAccount[posting.account, default: []].append(offset)
                byEntity[posting.entity, default: []].append(offset)
            }
        }

        self.journal = raw.journal
        self.postings = postings
        self.offsetsByEntry = byEntry
        self.offsetsByAccount = byAccount
        self.offsetsByEntity = byEntity
    }

    public var count: Int {
        postings.count
    }

    public func entry(_ id: Entry.ID) -> Entry? {
        journal.entry(id)
    }

    /// Original postings for this entry, in their original line order.
    public func postings(for entry: Entry.ID) -> [Posting] {
        (offsetsByEntry[entry] ?? []).map { postings[$0] }
    }

    /// Direct postings only. Ancestor rollups belong to Balances.
    public func postings(for account: Account.Reference) -> [Posting] {
        (offsetsByAccount[account] ?? []).map { postings[$0] }
    }

    public func postings(for entity: Entity.Reference) -> [Posting] {
        (offsetsByEntity[entity] ?? []).map { postings[$0] }
    }
}

