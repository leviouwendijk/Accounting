import Foundation
import Primitives

/// One complete, balanced accounting entry.
/// Construction establishes the entry's identity, date and balance invariants.
public struct Entry: Invariant, Sendable {
    public struct ID: Invariant, Hashable, Sendable {
        public enum Error: Swift.Error, Equatable, Sendable {
            case nonPositive
        }

        public let value: Int

        public init(_ raw: Int) throws(Error) {
            guard raw > 0 else { throw .nonPositive }
            self.value = raw
        }
    }

    /// A canonical financial line whose account and entity have been checked
    /// against validated definitions at construction time.
    public struct Line: Invariant, Sendable {
        public struct Raw: Sendable {
            public let account: Account.Reference
            public let entity: Entity.Reference
            public let direction: Direction
            public let amount: Decimal
            public let chart: Chart
            public let entities: Entities

            public init(
                account: Account.Reference,
                entity: Entity.Reference,
                direction: Direction,
                amount: Decimal,
                chart: Chart,
                entities: Entities
            ) {
                self.account = account
                self.entity = entity
                self.direction = direction
                self.amount = amount
                self.chart = chart
                self.entities = entities
            }
        }

        public enum Error: Swift.Error, Equatable, Sendable {
            case unknownAccount(Account.Reference)
            case nonPostableAccount(Account.Reference)
            case missingAccountCategory(Account.Reference)
            case unknownEntity(Entity.Reference)
            case nonPositiveAmount
        }

        public let account: Account.Reference
        public let entity: Entity.Reference
        public let direction: Direction
        public let amount: Decimal

        public init(_ raw: Raw) throws(Error) {
            guard let account = raw.chart.account(raw.account) else {
                throw .unknownAccount(raw.account)
            }
            guard account.postable else {
                throw .nonPostableAccount(raw.account)
            }
            guard account.category != nil else {
                throw .missingAccountCategory(raw.account)
            }
            guard raw.entities.entity(raw.entity) != nil else {
                throw .unknownEntity(raw.entity)
            }
            guard raw.amount > 0 else {
                throw .nonPositiveAmount
            }

            self.account = raw.account
            self.entity = raw.entity
            self.direction = raw.direction
            self.amount = raw.amount
        }

        /// Signed debit-minus-credit contribution to the entry's balance.
        public var signedAmount: Decimal {
            switch direction {
            case .debit:
                amount
            case .credit:
                -amount
            }
        }
    }

    public enum Sort: String, Hashable, Codable, Sendable {
        case regular
        case adjusting
    }

    public struct Raw: Sendable {
        public let id: ID
        public let date: Date
        public let lines: [Line]
        public let sort: Sort
        public let details: String?
        public let metadata: [String: String]

        public init(
            id: ID,
            date: Date,
            lines: [Line],
            sort: Sort = .regular,
            details: String? = nil,
            metadata: [String: String] = [:]
        ) {
            self.id = id
            self.date = date
            self.lines = lines
            self.sort = sort
            self.details = details
            self.metadata = metadata
        }
    }

    public enum Error: Swift.Error, Equatable, Sendable {
        case invalidDate
        case insufficientLines
        case emptyDetails
        case unbalanced(Decimal)
    }

    public let id: ID
    public let date: Date
    public let lines: [Line]
    public let sort: Sort
    public let details: String?
    public let metadata: [String: String]

    public init(_ raw: Raw) throws(Error) {
        guard raw.date.timeIntervalSinceReferenceDate.isFinite else {
            throw .invalidDate
        }
        guard raw.lines.count >= 2 else {
            throw .insufficientLines
        }
        if let details = raw.details,
            details.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        {
            throw .emptyDetails
        }

        let difference = raw.lines.reduce(Decimal.zero) { partial, line in
            partial + line.signedAmount
        }
        guard difference == 0 else {
            throw .unbalanced(difference)
        }

        self.id = raw.id
        self.date = raw.date
        self.lines = raw.lines
        self.sort = raw.sort
        self.details = raw.details
        self.metadata = raw.metadata
    }
}
