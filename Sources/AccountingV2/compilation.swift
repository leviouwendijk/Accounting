import Foundation
import Primitives

/// A derived accounting projection over a validated Composition.
/// Historical opening contributions may be reattributed according to the
/// chart's mandatory carryforward behavior. Current movements and accepted
/// calculation effects retain their original account attribution.
///
/// This does not automatically close historical temporary accounts or
/// establish that previous periods have been fully reconciled.
public struct Compilation: Invariant, Sendable {
    public enum Opening: Sendable {
        /// Preserve the original accounts of historical postings.
        case recorded

        /// Route only pre-period postings using the chart's declared policy.
        case carryforward
    }

    public struct Raw: Sendable {
        public let composition: Composition
        public let opening: Opening

        public init(composition: Composition, opening: Opening) {
            self.composition = composition
            self.opening = opening
        }
    }

    public typealias Error = Routing.Error

    /// Independent signed components of one projected account position.
    /// All Amount values retain their posted/total/descendants distinction.
    public struct Breakdown: Sendable {
        /// Original historical postings at their original account identities.
        public let recorded_opening: Balances.Amount

        /// Selected opening amount, possibly attributed to a new account.
        public let opening: Balances.Amount

        /// Original, unmapped postings from the current period.
        public let movements: Balances.Amount

        /// Effects already accepted by the originating Composition.
        public let calculated: Balances.Amount

        fileprivate init(
            recorded_opening: Balances.Amount,
            opening: Balances.Amount,
            movements: Balances.Amount,
            calculated: Balances.Amount
        ) {
            self.recorded_opening = recorded_opening
            self.opening = opening
            self.movements = movements
            self.calculated = calculated
        }

        /// Unadjusted cumulative position before closing or carryforward.
        public var recorded: Balances.Amount {
            Balances.Amount(
                posted: recorded_opening.posted + movements.posted,
                total: recorded_opening.total + movements.total
            )
        }

        /// The reclassification introduced by opening routing alone.
        public var routing_delta: Balances.Amount {
            Balances.Amount(
                posted: opening.posted - recorded_opening.posted,
                total: opening.total - recorded_opening.total
            )
        }

        /// Opening + current movements + accepted calculation effects.
        public var result: Balances.Amount {
            Balances.Amount(
                posted: opening.posted + movements.posted + calculated.posted,
                total: opening.total + movements.total + calculated.total
            )
        }
    }

    public let composition: Composition
    public let opening: Opening

    /// The traceable reattribution of historical postings, when selected.
    /// Nil means recorded opening was explicitly selected, not that no
    /// historical postings exist.
    public let routing: Routing?

    public init(_ raw: Raw) throws(Error) {
        let routing: Routing?
        switch raw.opening {
        case .recorded:
            routing = nil

        case .carryforward:
            routing = try Routing(.init(
                balances: raw.composition.period.opening
            ))
        }

        self.composition = raw.composition
        self.opening = raw.opening
        self.routing = routing
    }

    public var period: Period {
        composition.period
    }

    /// A known inactive account returns zero amounts; an unknown account or
    /// entity returns nil. No original source account is overwritten.
    public func breakdown(
        for account: Account.Reference,
        entity: Entity.Reference? = nil
    ) -> Breakdown? {
        guard let recordedOpening = period.opening.amount(
            for: account,
            entity: entity
        ), let movements = period.movements.amount(
            for: account,
            entity: entity
        ), let composed = composition.breakdown(
            for: account,
            entity: entity
        ) else {
            return nil
        }

        let selectedOpening: Balances.Amount
        if let routing {
            guard let amount = routing.amount(for: account, entity: entity) else {
                return nil
            }
            selectedOpening = amount
        } else {
            selectedOpening = recordedOpening
        }

        return Breakdown(
            recorded_opening: recordedOpening,
            opening: selectedOpening,
            movements: movements,
            calculated: composed.calculated
        )
    }

    public func amount(
        for account: Account.Reference,
        entity: Entity.Reference? = nil
    ) -> Balances.Amount? {
        breakdown(for: account, entity: entity)?.result
    }
}
