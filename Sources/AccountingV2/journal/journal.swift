import Foundation
import Primitives

/// An immutable collection of canonical entries under one validated
/// chart and entity registry. Source entries remain authoritative.
public struct Journal: Invariant, Sendable {
    public struct Raw: Sendable {
        public let entries: [Entry]
        public let chart: Chart
        public let entities: Entities

        public init(
            entries: [Entry],
            chart: Chart,
            entities: Entities
        ) {
            self.entries = entries
            self.chart = chart
            self.entities = entities
        }
    }

    public enum Error: Swift.Error, Equatable, Sendable {
        case duplicateEntry(Entry.ID)
        case unknownAccount(entry: Entry.ID, line: Int, account: Account.Reference)
        case nonPostableAccount(entry: Entry.ID, line: Int, account: Account.Reference)
        case missingAccountCategory(entry: Entry.ID, line: Int, account: Account.Reference)
        case unknownEntity(entry: Entry.ID, line: Int, entity: Entity.Reference)
    }

    public let entries: [Entry]
    public let chart: Chart
    public let entities: Entities
    private let entriesByID: [Entry.ID: Entry]

    public init(_ raw: Raw) throws(Error) {
        var index: [Entry.ID: Entry] = [:]
        index.reserveCapacity(raw.entries.count)

        for entry in raw.entries {
            guard index.updateValue(entry, forKey: entry.id) == nil else {
                throw .duplicateEntry(entry.id)
            }

            for (offset, line) in entry.lines.enumerated() {
                guard let account = raw.chart.account(line.account) else {
                    throw .unknownAccount(
                        entry: entry.id,
                        line: offset,
                        account: line.account
                    )
                }
                guard account.postable else {
                    throw .nonPostableAccount(
                        entry: entry.id,
                        line: offset,
                        account: line.account
                    )
                }
                guard account.category != nil else {
                    throw .missingAccountCategory(
                        entry: entry.id,
                        line: offset,
                        account: line.account
                    )
                }
                guard raw.entities.entity(line.entity) != nil else {
                    throw .unknownEntity(
                        entry: entry.id,
                        line: offset,
                        entity: line.entity
                    )
                }
            }
        }

        self.entries = raw.entries
        self.chart = raw.chart
        self.entities = raw.entities
        self.entriesByID = index
    }

    public var count: Int {
        entries.count
    }

    public func entry(_ id: Entry.ID) -> Entry? {
        entriesByID[id]
    }
}
