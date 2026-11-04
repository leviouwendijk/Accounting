import Foundation
import Primitives

/// An immutable composition of recorded accounting positions and
/// explicitly selected calculation effects.
/// Neither closing effects nor resulting totals become journal postings.
public struct Composition: Invariant, Sendable {
    /// Selection carries the originating Period. A closing audit cannot
    /// be accidentally combined with a separately supplied period.
    public enum Selection: Sendable {
        case recorded(Period)
        case accept_closing(Closing.Audit)
    }

    public struct Raw: Sendable {
        public let selection: Selection

        public init(selection: Selection) {
            self.selection = selection
        }
    }

    public enum Error: Swift.Error, Equatable, Sendable {
        case unknownEffectAccount(Account.Reference)
        case unknownEffectEntity(Entity.Reference)
        case unknownEffectSource(Posting.Source)
        case unbalancedEffects
        case unbalancedEntity(Entity.Reference)
    }

    /// Arithmetic is always debit-minus-credit.
    /// The result is derived and never overwrites recorded amounts.
    public struct Breakdown: Sendable {
        public let recorded: Balances.Amount
        public let calculated: Balances.Amount

        public var result: Balances.Amount {
            Balances.Amount(
                posted: recorded.posted + calculated.posted,
                total: recorded.total + calculated.total
            )
        }

        fileprivate init(
            recorded: Balances.Amount,
            calculated: Balances.Amount
        ) {
            self.recorded = recorded
            self.calculated = calculated
        }
    }

    public let selection: Selection
    public let period: Period
    public let effects: [Closing.Effect]

    private let direct: [Account.Reference: Decimal]
    private let rolled: [Account.Reference: Decimal]
    private let directByEntity: [Entity.Reference: [Account.Reference: Decimal]]
    private let rolledByEntity: [Entity.Reference: [Account.Reference: Decimal]]
    private let directOffsets: [Account.Reference: [Int]]
    private let rolledOffsets: [Account.Reference: [Int]]

    public init(_ raw: Raw) throws(Error) {
        let period: Period
        let effects: [Closing.Effect]

        switch raw.selection {
        case .recorded(let source):
            period = source
            effects = []

        case .accept_closing(let audit):
            period = audit.period
            effects = audit.effects
            guard audit.effectBalance == 0 else {
                throw .unbalancedEffects
            }
        }

        let chart = period.ledger.journal.chart
        let entities = period.ledger.journal.entities
        let knownSources = Set(period.movements.postings.map(\.source))

        var direct: [Account.Reference: Decimal] = [:]
        var rolled: [Account.Reference: Decimal] = [:]
        var directByEntity: [Entity.Reference: [Account.Reference: Decimal]] = [:]
        var rolledByEntity: [Entity.Reference: [Account.Reference: Decimal]] = [:]
        var directOffsets: [Account.Reference: [Int]] = [:]
        var rolledOffsets: [Account.Reference: [Int]] = [:]
        var entityBalance: [Entity.Reference: Decimal] = [:]

        for (offset, effect) in effects.enumerated() {
            guard chart.account(effect.account) != nil else {
                throw .unknownEffectAccount(effect.account)
            }
            guard entities.entity(effect.entity) != nil else {
                throw .unknownEffectEntity(effect.entity)
            }
            for source in effect.sources {
                guard knownSources.contains(source) else {
                    throw .unknownEffectSource(source)
                }
            }

            let signed = effect.signedAmount
            entityBalance[effect.entity, default: 0] += signed
            direct[effect.account, default: 0] += signed
            directOffsets[effect.account, default: []].append(offset)

            var entityDirect = directByEntity[effect.entity] ?? [:]
            entityDirect[effect.account, default: 0] += signed
            directByEntity[effect.entity] = entityDirect

            var entityRolled = rolledByEntity[effect.entity] ?? [:]
            for account in [effect.account] + (chart.ancestors(of: effect.account) ?? []) {
                rolled[account, default: 0] += signed
                entityRolled[account, default: 0] += signed
                rolledOffsets[account, default: []].append(offset)
            }
            rolledByEntity[effect.entity] = entityRolled
        }

        guard effects.reduce(Decimal.zero, { $0 + $1.signedAmount }) == 0 else {
            throw .unbalancedEffects
        }
        for (entity, amount) in entityBalance where amount != 0 {
            throw .unbalancedEntity(entity)
        }

        self.selection = raw.selection
        self.period = period
        self.effects = effects
        self.direct = direct
        self.rolled = rolled
        self.directByEntity = directByEntity
        self.rolledByEntity = rolledByEntity
        self.directOffsets = directOffsets
        self.rolledOffsets = rolledOffsets
    }

    /// The recorded position and selected derived contributions remain
    /// independently inspectable even when either net amount is zero.
    public func breakdown(
        for account: Account.Reference,
        entity: Entity.Reference? = nil
    ) -> Breakdown? {
        guard let recorded = period.position.amount(for: account, entity: entity) else {
            return nil
        }

        let calculated: Balances.Amount
        if let entity {
            calculated = Balances.Amount(
                posted: directByEntity[entity]?[account] ?? 0,
                total: rolledByEntity[entity]?[account] ?? 0
            )
        } else {
            calculated = Balances.Amount(
                posted: direct[account] ?? 0,
                total: rolled[account] ?? 0
            )
        }

        return Breakdown(recorded: recorded, calculated: calculated)
    }

    public func amount(
        for account: Account.Reference,
        entity: Entity.Reference? = nil
    ) -> Balances.Amount? {
        breakdown(for: account, entity: entity)?.result
    }

    /// Selected calculated effects targeting this exact account.
    public func effects(
        at account: Account.Reference,
        entity: Entity.Reference? = nil
    ) -> [Closing.Effect]? {
        effects(at: account, entity: entity, using: directOffsets)
    }

    /// Selected calculated effects contributing through this account's subtree.
    public func contributingEffects(
        to account: Account.Reference,
        entity: Entity.Reference? = nil
    ) -> [Closing.Effect]? {
        effects(at: account, entity: entity, using: rolledOffsets)
    }

    private func effects(
        at account: Account.Reference,
        entity: Entity.Reference?,
        using offsets: [Account.Reference: [Int]]
    ) -> [Closing.Effect]? {
        let journal = period.ledger.journal
        guard journal.chart.account(account) != nil else { return nil }
        if let entity, journal.entities.entity(entity) == nil { return nil }

        let selected = offsets[account] ?? []
        if let entity {
            return selected.compactMap { offset in
                let effect = effects[offset]
                return effect.entity == entity ? effect : nil
            }
        }
        return selected.map { effects[$0] }
    }
}
