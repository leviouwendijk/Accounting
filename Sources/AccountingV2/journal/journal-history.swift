import Foundation

public extension Journal {
    /// Exact, order-independent evidence of journal entries dated before a
    /// reporting boundary. This is not a hash or authenticated source ID.
    struct History: Equatable, Sendable {
        public struct Line: Equatable, Sendable {
            public let account: Account.Reference
            public let entity: Entity.Reference
            public let direction: Direction
            public let amount: Decimal

            public init(_ line: Entry.Line) {
                self.account = line.account
                self.entity = line.entity
                self.direction = line.direction
                self.amount = line.amount
            }
        }

        public struct SourceEntry: Equatable, Sendable {
            public let id: Entry.ID
            public let date: Date
            public let sort: Entry.Sort
            public let details: String?
            public let metadata: [String: String]
            public let lines: [Line]

            public init(_ entry: Entry) {
                self.id = entry.id
                self.date = entry.date
                self.sort = entry.sort
                self.details = entry.details
                self.metadata = entry.metadata
                self.lines = entry.lines.map(Line.init)
            }
        }

        public let boundary: Date
        public let entries: [SourceEntry]

        public init(_ journal: Journal, before boundary: Date) {
            self.boundary = boundary
            self.entries = journal.entries
                .filter { $0.date < boundary }
                .sorted { $0.id.value < $1.id.value }
                .map(SourceEntry.init)
        }
    }
}
