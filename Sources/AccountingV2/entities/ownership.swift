import Foundation
import Primitives

public extension Ownership {
    /// A canonical fraction in the closed interval 0...1.
    /// Callers must explicitly distinguish fractions from percentages.
    struct Share: Invariant, Hashable, Sendable {
        public typealias Raw = Decimal

        public enum Error: Swift.Error, Equatable, Sendable {
            case outOfRange
        }

        public let fraction: Decimal

        public init(_ raw: Raw) throws(Error) {
            guard raw >= 0 && raw <= 1 else {
                throw .outOfRange
            }
            self.fraction = raw
        }

        public init(fraction: Decimal) throws(Error) {
            try self.init(fraction)
        }

        public init(percent: Decimal) throws(Error) {
            guard percent >= 0 && percent <= 100 else {
                throw .outOfRange
            }
            try self.init(percent / 100)
        }
    }

    /// One owner's ownership fact, effective from an exact instant.
    struct State: Invariant, Sendable {
        public struct Raw: Sendable {
            public let effectiveFrom: Date
            public let share: Share
            public let details: String?

            public init(
                effectiveFrom: Date,
                share: Share,
                details: String? = nil
            ) {
                self.effectiveFrom = effectiveFrom
                self.share = share
                self.details = details
            }
        }

        public enum Error: Swift.Error, Equatable, Sendable {
            case invalidEffectiveDate
        }

        public let effectiveFrom: Date
        public let share: Share
        public let details: String?

        public init(_ raw: Raw) throws(Error) {
            guard raw.effectiveFrom.timeIntervalSinceReferenceDate.isFinite else {
                throw .invalidEffectiveDate
            }
            self.effectiveFrom = raw.effectiveFrom
            self.share = raw.share
            self.details = raw.details
        }

        public init(
            effectiveFrom: Date,
            share: Share,
            details: String? = nil
        ) throws(Error) {
            try self.init(.init(
                effectiveFrom: effectiveFrom,
                share: share,
                details: details
            ))
        }
    }

    /// A declared division of one owner's attributed amounts.
    /// This is a fact, not an instruction to mutate capital balances.
    struct Division: Sendable {
        public let recipient: Entity.Reference
        public let share: Share

        public init(recipient: Entity.Reference, share: Share) {
            self.recipient = recipient
            self.share = share
        }
    }

    struct Change: Invariant, Sendable {
        public struct Raw: Sendable {
            public let state: State
            public let divisions: [Division]

            public init(state: State, divisions: [Division] = []) {
                self.state = state
                self.divisions = divisions
            }
        }

        public enum Error: Swift.Error, Equatable, Sendable {
            case duplicateRecipient(Entity.Reference)
            case divisionsExceedWhole
        }

        public let state: State
        public let divisions: [Division]

        public init(_ raw: Raw) throws(Error) {
            var recipients: Set<Entity.Reference> = []
            var sum: Decimal = 0

            for division in raw.divisions {
                guard recipients.insert(division.recipient).inserted else {
                    throw .duplicateRecipient(division.recipient)
                }
                sum += division.share.fraction
            }

            guard sum <= 1 else {
                throw .divisionsExceedWhole
            }

            self.state = raw.state
            self.divisions = raw.divisions
        }

        public init(state: State, divisions: [Division] = []) throws(Error) {
            try self.init(.init(state: state, divisions: divisions))
        }
    }

    /// One owner's effective-dated history. Changes are retained in date order.
    /// No ownership state is assumed before the initial effective date.
    struct History: Invariant, Sendable {
        public struct Raw: Sendable {
            public let owner: Entity.Reference
            public let initial: State
            public let changes: [Change]

            public init(
                owner: Entity.Reference,
                initial: State,
                changes: [Change] = []
            ) {
                self.owner = owner
                self.initial = initial
                self.changes = changes
            }
        }

        public enum Error: Swift.Error, Equatable, Sendable {
            case changeNotAfterInitial
            case duplicateEffectiveDate
        }

        public let owner: Entity.Reference
        public let initial: State
        public let changes: [Change]

        public init(_ raw: Raw) throws(Error) {
            let ordered = raw.changes.sorted {
                $0.state.effectiveFrom < $1.state.effectiveFrom
            }

            for (index, change) in ordered.enumerated() {
                guard change.state.effectiveFrom > raw.initial.effectiveFrom else {
                    throw .changeNotAfterInitial
                }
                if index > 0 && ordered[index - 1].state.effectiveFrom == change.state.effectiveFrom {
                    throw .duplicateEffectiveDate
                }
            }

            self.owner = raw.owner
            self.initial = raw.initial
            self.changes = ordered
        }

        public init(
            owner: Entity.Reference,
            initial: State,
            changes: [Change] = []
        ) throws(Error) {
            try self.init(.init(owner: owner, initial: initial, changes: changes))
        }

        /// Exact effective-date lookup. The latest state at or before the
        /// requested date wins, independent of reporting-window boundaries.
        public func state(at date: Date) -> State? {
            guard date >= initial.effectiveFrom else { return nil }
            return change(at: date)?.state ?? initial
        }

        public func change(at date: Date) -> Change? {
            var lower = 0
            var upper = changes.count
            while lower < upper {
                let middle = lower + (upper - lower) / 2
                if changes[middle].state.effectiveFrom <= date {
                    lower = middle + 1
                } else {
                    upper = middle
                }
            }
            return lower == 0 ? nil : changes[lower - 1]
        }

        /// V1-compatible latest-change semantics: a subsequent change with
        /// no divisions replaces, rather than inherits, earlier divisions.
        public func divisions(at date: Date) -> [Division] {
            change(at: date)?.divisions ?? []
        }
    }

    /// Validated ownership histories bound to the existing entity registry.
    /// Does not implicitly normalize, allocate, or redistribute amounts.
    struct Portfolio: Invariant, Sendable {
        public struct Raw: Sendable {
            public let entities: Entities
            public let histories: [History]

            public init(entities: Entities, histories: [History]) {
                self.entities = entities
                self.histories = histories
            }
        }

        public enum Error: Swift.Error, Equatable, Sendable {
            case duplicateOwner(Entity.Reference)
            case unknownOwner(Entity.Reference)
            case unknownRecipient(Entity.Reference)
            case selfDivision(Entity.Reference)
        }

        public let entities: Entities
        public let histories: [History]
        private let byOwner: [Entity.Reference: History]

        public init(_ raw: Raw) throws(Error) {
            var indexed: [Entity.Reference: History] = [:]
            for history in raw.histories {
                guard raw.entities.entity(history.owner) != nil else {
                    throw .unknownOwner(history.owner)
                }
                guard indexed[history.owner] == nil else {
                    throw .duplicateOwner(history.owner)
                }
                for change in history.changes {
                    for division in change.divisions {
                        guard raw.entities.entity(division.recipient) != nil else {
                            throw .unknownRecipient(division.recipient)
                        }
                        guard division.recipient != history.owner else {
                            throw .selfDivision(history.owner)
                        }
                    }
                }
                indexed[history.owner] = history
            }
            self.entities = raw.entities
            self.histories = raw.histories
            self.byOwner = indexed
        }

        public init(entities: Entities, histories: [History]) throws(Error) {
            try self.init(.init(entities: entities, histories: histories))
        }

        public func history(for owner: Entity.Reference) -> History? {
            byOwner[owner]
        }

        public func state(for owner: Entity.Reference, at date: Date) -> State? {
            byOwner[owner]?.state(at: date)
        }

        public func states(at date: Date) -> [Entity.Reference: State] {
            var result: [Entity.Reference: State] = [:]
            for history in histories {
                if let state = history.state(at: date) {
                    result[history.owner] = state
                }
            }
            return result
        }
    }
}
