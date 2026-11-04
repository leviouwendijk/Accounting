import Foundation
import Primitives

/// Advances one accepted financial position through one bounded period.
/// Historical postings are not replayed: only current movements and
/// explicitly selected calculation effects contribute to the next state.
public struct Continuity: Invariant, Sendable {
    public enum Opening: Sendable {
        /// Keep the accepted prior state on its existing account identities.
        case as_is

        /// Reattribute the accepted state using declared chart behavior.
        /// The supplied lineage must identify the prior state as an input.
        case carryforward(provenance: Provenance)
    }

    public struct Raw: Sendable {
        public let prior_state: PositionState
        public let composition: Composition
        public let opening: Opening
        public let provenance: Provenance

        public init(
            prior_state: PositionState,
            composition: Composition,
            opening: Opening,
            provenance: Provenance
        ) {
            self.prior_state = prior_state
            self.composition = composition
            self.opening = opening
            self.provenance = provenance
        }
    }

    public enum Error: Swift.Error, Equatable, Sendable {
        case boundaryMismatch
        case incompatibleChart
        case incompatibleEntities
        case invalidCarryforwardLineage
        case missingOpeningLineage(Provenance.Identifier)
        case reusedResultIdentifier
        case invalidOpeningState(PositionState.Error)
        case invalidResultState(PositionState.Error)
    }

    private struct Key: Hashable, Sendable {
        let account: Account.Reference
        let entity: Entity.Reference
    }

    public struct Breakdown: Sendable {
        public let prior: Balances.Amount
        public let opening: Balances.Amount
        public let movements: Balances.Amount
        public let calculated: Balances.Amount

        fileprivate init(
            prior: Balances.Amount,
            opening: Balances.Amount,
            movements: Balances.Amount,
            calculated: Balances.Amount
        ) {
            self.prior = prior
            self.opening = opening
            self.movements = movements
            self.calculated = calculated
        }

        public var routing_delta: Balances.Amount {
            Balances.Amount(
                posted: opening.posted - prior.posted,
                total: opening.total - prior.total
            )
        }

        public var result: Balances.Amount {
            Balances.Amount(
                posted: opening.posted + movements.posted + calculated.posted,
                total: opening.total + movements.total + calculated.total
            )
        }
    }

    public let prior_state: PositionState
    public let opening_state: PositionState
    public let composition: Composition
    public let opening: Opening
    public let result: PositionState

    public init(_ raw: Raw) throws(Error) {
        let period = raw.composition.period
        let journal = period.ledger.journal

        guard raw.prior_state.boundary == period.start else {
            throw .boundaryMismatch
        }
        guard raw.prior_state.chart.isCompatibleForContinuity(
            with: journal.chart
        ) else {
            throw .incompatibleChart
        }

        let previousEntities = raw.prior_state.entities
        guard previousEntities.count == journal.entities.count else {
            throw .incompatibleEntities
        }
        for entity in previousEntities.all {
            guard let current = journal.entities.entity(entity.reference),
                  current.displayName == entity.displayName,
                  current.details == entity.details,
                  current.metadata == entity.metadata
            else {
                throw .incompatibleEntities
            }
        }

        let selectedOpening: PositionState
        switch raw.opening {
        case .as_is:
            selectedOpening = raw.prior_state

        case .carryforward(let provenance):
            guard provenance.result != raw.prior_state.provenance.result,
                  provenance.inputs.contains(
                    .calculation(raw.prior_state.provenance.result)
                  )
            else {
                throw .invalidCarryforwardLineage
            }
            do {
                selectedOpening = try raw.prior_state.carryforward(
                    provenance: provenance
                )
            } catch {
                throw .invalidOpeningState(error)
            }
        }

        guard raw.provenance.result != selectedOpening.provenance.result else {
            throw .reusedResultIdentifier
        }
        guard raw.provenance.inputs.contains(
            .calculation(selectedOpening.provenance.result)
        ) else {
            throw .missingOpeningLineage(selectedOpening.provenance.result)
        }

        var cells = selectedOpening.cells
        var offsets: [Key: Int] = [:]
        for (index, cell) in cells.enumerated() {
            offsets[Key(account: cell.account, entity: cell.entity)] = index
        }

        func add(
            account: Account.Reference,
            entity: Entity.Reference,
            amount: Decimal
        ) {
            let key = Key(account: account, entity: entity)
            if let index = offsets[key] {
                let existing = cells[index]
                cells[index] = PositionState.Cell(
                    account: account,
                    entity: entity,
                    amount: existing.amount + amount
                )
            } else {
                offsets[key] = cells.count
                cells.append(PositionState.Cell(
                    account: account,
                    entity: entity,
                    amount: amount
                ))
            }
        }

        // Do not consume period.opening or period.position. The accepted
        // prior state already contains all approved historical activity.
        for posting in period.movements.postings {
            add(
                account: posting.account,
                entity: posting.entity,
                amount: posting.signedAmount
            )
        }
        for effect in raw.composition.effects {
            add(
                account: effect.account,
                entity: effect.entity,
                amount: effect.signedAmount
            )
        }

        let result: PositionState
        do {
            result = try PositionState(.init(
                chart: journal.chart,
                entities: journal.entities,
                boundary: period.end,
                cells: cells,
                provenance: raw.provenance
            ))
        } catch {
            throw .invalidResultState(error)
        }

        self.prior_state = raw.prior_state
        self.opening_state = selectedOpening
        self.composition = raw.composition
        self.opening = raw.opening
        self.result = result
    }

    public func breakdown(
        for account: Account.Reference,
        entity: Entity.Reference? = nil
    ) -> Breakdown? {
        guard let prior = prior_state.amount(for: account, entity: entity),
              let opening = opening_state.amount(for: account, entity: entity),
              let movements = composition.period.movements.amount(
                for: account,
                entity: entity
              ),
              let calculated = composition.breakdown(
                for: account,
                entity: entity
              )?.calculated
        else {
            return nil
        }

        return Breakdown(
            prior: prior,
            opening: opening,
            movements: movements,
            calculated: calculated
        )
    }

    public func amount(
        for account: Account.Reference,
        entity: Entity.Reference? = nil
    ) -> Balances.Amount? {
        result.amount(for: account, entity: entity)
    }
}
