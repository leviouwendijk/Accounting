import Foundation
import Primitives

/// An immutable financial position at an explicit historical boundary.
/// Cells represent signed direct account/entity positions, not postings.
/// Hierarchical amounts are derived from the validated chart.
///
/// Source history is represented by provenance references rather than
/// retaining the originating Ledger or Compilation.
public struct PositionState: Invariant, Sendable {
    public struct Cell: Sendable {
        public let account: Account.Reference
        public let entity: Entity.Reference
        public let amount: Decimal

        public init(
            account: Account.Reference,
            entity: Entity.Reference,
            amount: Decimal
        ) {
            self.account = account
            self.entity = entity
            self.amount = amount
        }
    }

    public struct Raw: Sendable {
        public let chart: Chart
        public let entities: Entities
        public let boundary: Date
        public let cells: [Cell]
        public let provenance: Provenance

        public init(
            chart: Chart,
            entities: Entities,
            boundary: Date,
            cells: [Cell],
            provenance: Provenance
        ) {
            self.chart = chart
            self.entities = entities
            self.boundary = boundary
            self.cells = cells
            self.provenance = provenance
        }
    }

    public enum Error: Swift.Error, Equatable, Sendable {
        case invalidBoundary
        case unknownAccount(Account.Reference)
        case unknownEntity(Entity.Reference)
        case duplicateCell(account: Account.Reference, entity: Entity.Reference)
        case unbalancedPosition
        case unmappedAccount(Account.Reference)
    }

    private struct Key: Hashable, Sendable {
        let account: Account.Reference
        let entity: Entity.Reference
    }

    public let chart: Chart
    public let entities: Entities
    public let boundary: Date
    public let cells: [Cell]
    public let provenance: Provenance

    private let direct: [Account.Reference: Decimal]
    private let rolled: [Account.Reference: Decimal]
    private let directByEntity: [Entity.Reference: [Account.Reference: Decimal]]
    private let rolledByEntity: [Entity.Reference: [Account.Reference: Decimal]]

    public init(_ raw: Raw) throws(Error) {
        guard raw.boundary.timeIntervalSinceReferenceDate.isFinite else {
            throw .invalidBoundary
        }

        var seen: Set<Key> = []
        var direct: [Account.Reference: Decimal] = [:]
        var rolled: [Account.Reference: Decimal] = [:]
        var directEntities: [Entity.Reference: [Account.Reference: Decimal]] = [:]
        var rolledEntities: [Entity.Reference: [Account.Reference: Decimal]] = [:]
        var balance = Decimal.zero

        for cell in raw.cells {
            guard raw.chart.account(cell.account) != nil else {
                throw .unknownAccount(cell.account)
            }
            guard raw.entities.entity(cell.entity) != nil else {
                throw .unknownEntity(cell.entity)
            }
            guard seen.insert(Key(account: cell.account, entity: cell.entity)).inserted else {
                throw .duplicateCell(account: cell.account, entity: cell.entity)
            }

            balance += cell.amount
            direct[cell.account, default: 0] += cell.amount

            var entityDirect = directEntities[cell.entity] ?? [:]
            entityDirect[cell.account, default: 0] += cell.amount
            directEntities[cell.entity] = entityDirect

            var entityRolled = rolledEntities[cell.entity] ?? [:]
            for account in [cell.account] + (raw.chart.ancestors(of: cell.account) ?? []) {
                rolled[account, default: 0] += cell.amount
                entityRolled[account, default: 0] += cell.amount
            }
            rolledEntities[cell.entity] = entityRolled
        }

        guard balance == 0 else {
            throw .unbalancedPosition
        }

        self.chart = raw.chart
        self.entities = raw.entities
        self.boundary = raw.boundary
        self.cells = raw.cells
        self.provenance = raw.provenance
        self.direct = direct
        self.rolled = rolled
        self.directByEntity = directEntities
        self.rolledByEntity = rolledEntities
    }

    /// Materialize the selected result of an existing Compilation.
    /// Routing applies only to opening contributions; current movements
    /// and accepted calculation effects retain their declared accounts.
    /// Zero-net cells remain represented if contributions existed.
    public init(
        compilation: Compilation,
        provenance: Provenance
    ) throws(Error) {
        var cells: [Cell] = []
        var offsets: [Key: Int] = [:]

        func add(
            account: Account.Reference,
            entity: Entity.Reference,
            amount: Decimal
        ) {
            let key = Key(account: account, entity: entity)
            if let offset = offsets[key] {
                let previous = cells[offset]
                cells[offset] = Cell(
                    account: account,
                    entity: entity,
                    amount: previous.amount + amount
                )
            } else {
                offsets[key] = cells.count
                cells.append(Cell(account: account, entity: entity, amount: amount))
            }
        }

        if let routing = compilation.routing {
            for contribution in routing.contributions {
                add(
                    account: contribution.destination,
                    entity: contribution.entity,
                    amount: contribution.signedAmount
                )
            }
        } else {
            for posting in compilation.period.opening.postings {
                add(
                    account: posting.account,
                    entity: posting.entity,
                    amount: posting.signedAmount
                )
            }
        }

        for posting in compilation.period.movements.postings {
            add(
                account: posting.account,
                entity: posting.entity,
                amount: posting.signedAmount
            )
        }

        for effect in compilation.composition.effects {
            add(
                account: effect.account,
                entity: effect.entity,
                amount: effect.signedAmount
            )
        }

        try self.init(Raw(
            chart: compilation.period.ledger.journal.chart,
            entities: compilation.period.ledger.journal.entities,
            boundary: compilation.period.end,
            cells: cells,
            provenance: provenance
        ))
    }

    /// Reattribute each direct position once according to the chart's
    /// validated carryforward behavior. No prior calculation is rerun.
    /// The original state remains unchanged and inspectable.
    public func carryforward(
        provenance: Provenance
    ) throws(Error) -> PositionState {
        var cells: [Cell] = []
        var offsets: [Key: Int] = [:]

        for cell in self.cells {
            guard let destination = chart.carryforwardDestination(for: cell.account) else {
                throw .unmappedAccount(cell.account)
            }

            let key = Key(account: destination, entity: cell.entity)
            if let offset = offsets[key] {
                let previous = cells[offset]
                cells[offset] = Cell(
                    account: destination,
                    entity: cell.entity,
                    amount: previous.amount + cell.amount
                )
            } else {
                offsets[key] = cells.count
                cells.append(Cell(
                    account: destination,
                    entity: cell.entity,
                    amount: cell.amount
                ))
            }
        }

        return try PositionState(Raw(
            chart: chart,
            entities: entities,
            boundary: boundary,
            cells: cells,
            provenance: provenance
        ))
    }

    /// The state contains direct signed amounts. Ancestor totals are
    /// derived, not stored as separate source contributions.
    public func amount(
        for account: Account.Reference,
        entity: Entity.Reference? = nil
    ) -> Balances.Amount? {
        guard chart.account(account) != nil else { return nil }

        if let entity {
            guard entities.entity(entity) != nil else { return nil }
            return Balances.Amount(
                posted: directByEntity[entity]?[account] ?? 0,
                total: rolledByEntity[entity]?[account] ?? 0
            )
        }

        return Balances.Amount(
            posted: direct[account] ?? 0,
            total: rolled[account] ?? 0
        )
    }
}
