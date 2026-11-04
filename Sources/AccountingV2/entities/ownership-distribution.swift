import Foundation

public extension Ownership.Structure {
    /// Monetary attribution through explicit collapse routes. Ownership shares
    /// do not allocate existing balances between unrelated direct owners.
    struct Distribution: Sendable {
        public let snapshot: Snapshot
        public let recorded: [Entity.Reference: Decimal]
        public let effective: [Entity.Reference: Decimal]
        /// Effective less recorded, with no corresponding journal mutation.
        public let adjustments: [Entity.Reference: Decimal]

        public var recordedTotal: Decimal {
            recorded.values.reduce(Decimal.zero, +)
        }

        public var effectiveTotal: Decimal {
            effective.values.reduce(Decimal.zero, +)
        }

        public var adjustmentTotal: Decimal {
            adjustments.values.reduce(Decimal.zero, +)
        }
    }

    enum DistributionError: Swift.Error, Equatable, Sendable {
        case missingSnapshot(Date)
        case inactiveOwner(owner: Entity.Reference, date: Date)
        case unresolvedCollapse(owner: Entity.Reference, date: Date)
        case cycle(owner: Entity.Reference, date: Date)
        case nonconserving(Decimal)
    }

    /// Resolves a signed account/entity amount at a specific ownership state.
    /// A zero-share collapsing owner can still hold recorded capital, but an
    /// explicit route must exist to attribute a nonzero amount effectively.
    func distribute(
        _ recorded: [Entity.Reference: Decimal],
        at date: Date
    ) throws(DistributionError) -> Distribution {
        guard let snapshot = snapshot(at: date) else {
            throw .missingSnapshot(date)
        }
        for owner in recorded.keys where snapshot.declared[owner] == nil {
            throw .inactiveOwner(owner: owner, date: date)
        }

        var effective: [Entity.Reference: Decimal] = [:]
        func resolve(
            owner: Entity.Reference,
            amount: Decimal,
            visited: Set<Entity.Reference>
        ) throws(DistributionError) {
            guard amount != 0 else { return }
            guard collapsing.contains(owner) else {
                effective[owner, default: 0] += amount
                return
            }
            guard !visited.contains(owner) else {
                throw .cycle(owner: owner, date: date)
            }
            guard let divisions = snapshot.routes[owner] else {
                throw .unresolvedCollapse(owner: owner, date: date)
            }
            let active = divisions.filter { $0.share.fraction > 0 }.sorted {
                $0.recipient.identifier < $1.recipient.identifier
            }
            guard !active.isEmpty else {
                throw .unresolvedCollapse(owner: owner, date: date)
            }
            let next = visited.union([owner])
            var assigned = Decimal.zero
            for (index, division) in active.enumerated() {
                // Assign the final remainder deterministically, including for
                // negative balances, without imposing currency rounding.
                let part = index == active.count - 1
                    ? amount - assigned
                    : amount * division.share.fraction
                try resolve(owner: division.recipient, amount: part, visited: next)
                assigned += part
            }
        }

        for (owner, amount) in recorded.sorted(by: {
            $0.key.identifier < $1.key.identifier
        }) {
            try resolve(owner: owner, amount: amount, visited: [])
        }
        let recordedTotal = recorded.values.reduce(Decimal.zero, +)
        let effectiveTotal = effective.values.reduce(Decimal.zero, +)
        guard recordedTotal == effectiveTotal else {
            throw .nonconserving(recordedTotal - effectiveTotal)
        }
        var adjustments: [Entity.Reference: Decimal] = [:]
        for owner in Set(recorded.keys).union(effective.keys) {
            let change = (effective[owner] ?? 0) - (recorded[owner] ?? 0)
            if change != 0 {
                adjustments[owner] = change
            }
        }
        return Distribution(
            snapshot: snapshot,
            recorded: recorded,
            effective: effective,
            adjustments: adjustments
        )
    }
}
