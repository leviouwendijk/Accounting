import Foundation
import AccountingV2

/// Shared canonical fixture for V2 accounting integration and CLI smoke runs.
/// The original small 100...200 interval remains unchanged for existing tests.
public struct V2ClosingFixture: Sendable {
    public let chart: Chart
    public let entities: Entities
    public let bank: Account.Reference
    public let revenue: Account.Reference
    public let expenses: Account.Reference
    public let dividends: Account.Reference
    public let equity: Account.Reference
    public let heading: Account.Reference
    public let owner: Entity.Reference
    public let secondOwner: Entity.Reference

    public init() throws {
        let root = try Account(.init(code: "ROOT", postable: false))
        let bank = try Account(.init(code: "BANK", category: .assets, postable: true))
        let revenue = try Account(.init(code: "REVENUE", category: .revenue, postable: true))
        let expenses = try Account(.init(code: "EXPENSE", category: .expenses, postable: true))
        let dividends = try Account(.init(code: "DRAWINGS", category: .dividends, postable: true))
        let equity = try Account(.init(code: "EQUITY", category: .equity, postable: true))

        self.chart = try Chart(.init(
            accounts: [root, bank, revenue, expenses, dividends, equity],
            roots: [root.reference],
            parents: [
                bank.reference: root.reference,
                revenue.reference: root.reference,
                expenses.reference: root.reference,
                dividends.reference: root.reference,
                equity.reference: root.reference
            ],
            behavior: .init(carryforward: .identity)
        ))
        self.bank = bank.reference
        self.revenue = revenue.reference
        self.expenses = expenses.reference
        self.dividends = dividends.reference
        self.equity = equity.reference
        self.heading = root.reference

        let owner = try Entity.Reference(
            class: "person", family: "owner", alias: Entity.Alias(name: "owner-a")
        )
        let secondOwner = try Entity.Reference(
            class: "person", family: "owner", alias: Entity.Alias(name: "owner-b")
        )
        self.owner = owner
        self.secondOwner = secondOwner
        self.entities = try Entities([
            Entity(.init(reference: owner)),
            Entity(.init(reference: secondOwner))
        ])
    }

    public var accountOrder: [Account.Reference] {
        [heading, bank, revenue, expenses, dividends, equity]
    }

    public func entry(
        id: Int,
        time: TimeInterval = 150,
        entity: Entity.Reference? = nil,
        debit: Account.Reference,
        credit: Account.Reference,
        amount: Decimal
    ) throws -> Entry {
        let entity = entity ?? owner
        let first = try Entry.Line(.init(
            account: debit,
            entity: entity,
            direction: .debit,
            amount: amount,
            chart: chart,
            entities: entities
        ))
        let second = try Entry.Line(.init(
            account: credit,
            entity: entity,
            direction: .credit,
            amount: amount,
            chart: chart,
            entities: entities
        ))
        return try Entry(.init(
            id: Entry.ID(id),
            date: Date(timeIntervalSince1970: time),
            lines: [first, second]
        ))
    }

    public func period(_ entries: [Entry]) throws -> Period {
        let journal = try Journal(.init(
            entries: entries,
            chart: chart,
            entities: entities
        ))
        let ledger = try Ledger(.init(journal: journal))
        return try Period(.init(
            ledger: ledger,
            start: Date(timeIntervalSince1970: 100),
            end: Date(timeIntervalSince1970: 200)
        ))
    }

    /// A fixed, calendar-dated demonstration ledger.
    /// It includes one earlier-period entry, four current-period entries,
    /// and one future entry which must not affect a 2026 compilation.
    public func sampleLedger() throws -> Ledger {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]

        func timestamp(_ value: String) throws -> TimeInterval {
            guard let date = formatter.date(from: value) else {
                throw SampleError.invalidDate(value)
            }
            return date.timeIntervalSince1970
        }

        let entries = [
            try entry(
                id: 1, time: timestamp("2025-12-15"),
                debit: bank, credit: revenue, amount: 40
            ),
            try entry(
                id: 2, time: timestamp("2026-03-01"),
                debit: bank, credit: revenue, amount: 200
            ),
            try entry(
                id: 3, time: timestamp("2026-06-01"),
                debit: expenses, credit: bank, amount: 75
            ),
            try entry(
                id: 4, time: timestamp("2026-10-01"),
                debit: dividends, credit: bank, amount: 10
            ),
            try entry(
                id: 5, time: timestamp("2026-09-01"),
                entity: secondOwner,
                debit: bank, credit: revenue, amount: 80
            ),
            try entry(
                id: 6, time: timestamp("2027-02-01"),
                debit: bank, credit: revenue, amount: 300
            )
        ]

        let journal = try Journal(.init(
            entries: entries,
            chart: chart,
            entities: entities
        ))
        return try Ledger(.init(journal: journal))
    }

    public enum SampleError: Swift.Error, Sendable {
        case invalidDate(String)
    }
}
