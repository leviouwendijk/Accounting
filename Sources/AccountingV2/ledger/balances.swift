import Foundation
import Primitives

/// Immutable financial aggregation of an invariant Ledger.
/// Amounts retain debit-minus-credit signs; no category-specific normal-side
/// conventions or statement presentation rules are applied here.
/// Every contribution remains traceable to an original Posting.
public struct Balances: Invariant, Sendable {
    public struct Raw: Sendable {
        public let ledger: Ledger

        public init(ledger: Ledger) {
            self.ledger = ledger
        }
    }

    /// Aggregation cannot fail once its Ledger has established its invariants.
    public typealias Error = Never

    /// Signed amounts for one chart account, optionally restricted to an entity.
    /// Posted means exact-account activity; total includes all descendants.
    public struct Amount: Sendable {
        public let posted: Decimal
        public let total: Decimal

        public var descendants: Decimal {
            total - posted
        }

        init(posted: Decimal, total: Decimal) {
            self.posted = posted
            self.total = total
        }
    }

    public let ledger: Ledger

    private let directTotals: [Account.Reference: Decimal]
    private let rolledTotals: [Account.Reference: Decimal]
    private let directByEntity: [Entity.Reference: [Account.Reference: Decimal]]
    private let rolledByEntity: [Entity.Reference: [Account.Reference: Decimal]]
    private let directPostingOffsets: [Account.Reference: [Int]]
    private let rolledPostingOffsets: [Account.Reference: [Int]]
    private let selectedPostingOffsets: [Int]

    /// The full-ledger projection remains the default construction path.
    public init(_ raw: Raw) {
        self.init(ledger: raw.ledger, including: { _ in true })
    }

    /// An internal selection over the same authoritative Ledger.
    /// The predicate only accepts or excludes existing postings; it cannot
    /// manufacture postings or change their original source coordinates.
    init(ledger: Ledger, including includes: (Posting) -> Bool) {
        let offsets = ledger.postings.indices.filter {
            includes(ledger.postings[$0])
        }
        self.init(ledger: ledger, selectedPostingOffsets: offsets)
    }

    /// Aggregate an internally selected sequence of original ledger offsets.
    /// Offsets must be valid, unique, and in original journal order.
    /// Selection construction is responsible for those preconditions.
    init(ledger: Ledger, selectedPostingOffsets: [Int]) {
        let chart = ledger.journal.chart

        var direct: [Account.Reference: Decimal] = [:]
        var rolled: [Account.Reference: Decimal] = [:]
        var directEntities: [Entity.Reference: [Account.Reference: Decimal]] = [:]
        var rolledEntities: [Entity.Reference: [Account.Reference: Decimal]] = [:]
        var directOffsets: [Account.Reference: [Int]] = [:]
        var rolledOffsets: [Account.Reference: [Int]] = [:]
        for offset in selectedPostingOffsets {
            let posting = ledger.postings[offset]
            directOffsets[posting.account, default: []].append(offset)

            let amount = posting.signedAmount
            direct[posting.account, default: 0] += amount

            var entityDirect = directEntities[posting.entity] ?? [:]
            entityDirect[posting.account, default: 0] += amount
            directEntities[posting.entity] = entityDirect

            var entityRolled = rolledEntities[posting.entity] ?? [:]
            let ancestry = chart.ancestors(of: posting.account) ?? []
            for account in [posting.account] + ancestry {
                rolled[account, default: 0] += amount
                entityRolled[account, default: 0] += amount
                rolledOffsets[account, default: []].append(offset)
            }
            rolledEntities[posting.entity] = entityRolled
        }

        self.ledger = ledger
        self.directTotals = direct
        self.rolledTotals = rolled
        self.directByEntity = directEntities
        self.rolledByEntity = rolledEntities
        self.directPostingOffsets = directOffsets
        self.rolledPostingOffsets = rolledOffsets
        self.selectedPostingOffsets = selectedPostingOffsets
    }

    /// Original postings included in this projection, in journal order.
    /// The retained ledger may contain additional postings outside the selection.
    public var postings: [Posting] {
        selectedPostingOffsets.map { ledger.postings[$0] }
    }

    /// Returns signed exact-account and subtree amounts.
    /// A known inactive account returns zero amounts, an unknown reference nil.
    public func amount(
        for account: Account.Reference,
        entity: Entity.Reference? = nil
    ) -> Amount? {
        guard ledger.journal.chart.account(account) != nil else {
            return nil
        }
        if let entity {
            guard ledger.journal.entities.entity(entity) != nil else {
                return nil
            }
            return Amount(
                posted: directByEntity[entity]?[account] ?? 0,
                total: rolledByEntity[entity]?[account] ?? 0
            )
        }
        return Amount(
            posted: directTotals[account] ?? 0,
            total: rolledTotals[account] ?? 0
        )
    }

    /// Original postings targeting this exact account in this projection.
    /// A zero net posted amount does not imply an empty posting collection.
    public func postings(
        at account: Account.Reference,
        entity: Entity.Reference? = nil
    ) -> [Posting]? {
        guard ledger.journal.chart.account(account) != nil else {
            return nil
        }
        if let entity, ledger.journal.entities.entity(entity) == nil {
            return nil
        }

        let offsets = directPostingOffsets[account] ?? []
        if let entity {
            return offsets.compactMap { offset in
                let posting = ledger.postings[offset]
                return posting.entity == entity ? posting : nil
            }
        }
        return offsets.map { ledger.postings[$0] }
    }

    /// Original postings contributing to an account's rolled amount.
    /// The returned postings retain journal/line order and their source coordinates.
    /// This does not create ancestor postings or duplicate recorded activity.
    public func contributingPostings(
        to account: Account.Reference,
        entity: Entity.Reference? = nil
    ) -> [Posting]? {
        guard ledger.journal.chart.account(account) != nil else {
            return nil
        }
        if let entity, ledger.journal.entities.entity(entity) == nil {
            return nil
        }

        let offsets = rolledPostingOffsets[account] ?? []
        if let entity {
            return offsets.compactMap { offset in
                let posting = ledger.postings[offset]
                return posting.entity == entity ? posting : nil
            }
        }
        return offsets.map { ledger.postings[$0] }
    }
}
