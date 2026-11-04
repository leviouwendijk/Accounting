import Foundation
import Primitives

/// A carryforward projection over selected, original ledger postings.
/// Account attribution may change; the underlying posting never does.
public struct Routing: Invariant, Sendable {
    public struct Raw: Sendable {
        public let balances: Balances

        public init(balances: Balances) {
            self.balances = balances
        }
    }

    public enum Error: Swift.Error, Equatable, Sendable {
        case unmappedAccount(Account.Reference)
    }

    /// One original posting attributed to a configured destination.
    /// Not a new ledger posting or a journal mutation.
    public struct Contribution: Sendable {
        public let posting: Posting
        public let destination: Account.Reference

        fileprivate init(posting: Posting, destination: Account.Reference) {
            self.posting = posting
            self.destination = destination
        }

        public var source: Posting.Source { posting.source }
        public var originalAccount: Account.Reference { posting.account }
        public var entity: Entity.Reference { posting.entity }
        public var signedAmount: Decimal { posting.signedAmount }
    }

    public let balances: Balances
    public let contributions: [Contribution]

    private let posted: [Account.Reference: Decimal]
    private let total: [Account.Reference: Decimal]
    private let postedByEntity: [Entity.Reference: [Account.Reference: Decimal]]
    private let totalByEntity: [Entity.Reference: [Account.Reference: Decimal]]
    private let offsetsByDestination: [Account.Reference: [Int]]

    public init(_ raw: Raw) throws(Error) {
        let chart = raw.balances.ledger.journal.chart
        var contributions: [Contribution] = []
        contributions.reserveCapacity(raw.balances.postings.count)

        var posted: [Account.Reference: Decimal] = [:]
        var total: [Account.Reference: Decimal] = [:]
        var postedByEntity: [Entity.Reference: [Account.Reference: Decimal]] = [:]
        var totalByEntity: [Entity.Reference: [Account.Reference: Decimal]] = [:]
        var offsets: [Account.Reference: [Int]] = [:]

        for posting in raw.balances.postings {
            guard let destination = chart.carryforwardDestination(for: posting.account) else {
                throw .unmappedAccount(posting.account)
            }

            let offset = contributions.count
            contributions.append(Contribution(
                posting: posting,
                destination: destination
            ))
            offsets[destination, default: []].append(offset)

            let signed = posting.signedAmount
            posted[destination, default: 0] += signed

            var entityPosted = postedByEntity[posting.entity] ?? [:]
            entityPosted[destination, default: 0] += signed
            postedByEntity[posting.entity] = entityPosted

            var entityTotal = totalByEntity[posting.entity] ?? [:]
            for account in [destination] + (chart.ancestors(of: destination) ?? []) {
                total[account, default: 0] += signed
                entityTotal[account, default: 0] += signed
            }
            totalByEntity[posting.entity] = entityTotal
        }

        self.balances = raw.balances
        self.contributions = contributions
        self.posted = posted
        self.total = total
        self.postedByEntity = postedByEntity
        self.totalByEntity = totalByEntity
        self.offsetsByDestination = offsets
    }

    /// Amounts are computed on destination identities, after routing.
    /// Known inactive accounts return zeros; unknown accounts/entities nil.
    public func amount(
        for account: Account.Reference,
        entity: Entity.Reference? = nil
    ) -> Balances.Amount? {
        let journal = balances.ledger.journal
        guard journal.chart.account(account) != nil else { return nil }

        if let entity {
            guard journal.entities.entity(entity) != nil else { return nil }
            return Balances.Amount(
                posted: postedByEntity[entity]?[account] ?? 0,
                total: totalByEntity[entity]?[account] ?? 0
            )
        }

        return Balances.Amount(
            posted: posted[account] ?? 0,
            total: total[account] ?? 0
        )
    }

    /// Original contributions targeting exactly this destination account.
    /// Distinct original posting origins are never merged or discarded.
    public func contributions(
        to account: Account.Reference,
        entity: Entity.Reference? = nil
    ) -> [Contribution]? {
        let journal = balances.ledger.journal
        guard journal.chart.account(account) != nil else { return nil }
        if let entity, journal.entities.entity(entity) == nil { return nil }

        let indexes = offsetsByDestination[account] ?? []
        if let entity {
            return indexes.compactMap { index in
                let contribution = contributions[index]
                return contribution.entity == entity ? contribution : nil
            }
        }
        return indexes.map { contributions[$0] }
    }
}
