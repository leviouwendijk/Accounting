import Foundation

public struct OwnershipState: Codable, Sendable {
    public let date: Date
    public let percentage: Decimal
    public let details: String?

    public init(
        date: Date,
        percentage: Decimal,
        details: String?
    ) {
        self.date = date
        self.percentage = percentage
        self.details = details
    }
}

// Backward-compatibility alias for any older references.
public typealias OwnershipPercentage = OwnershipState

public struct OwnershipDivideEntry: Codable, Sendable {
    public let owner: EntityRef
    public let percent: Decimal

    public init(
        owner: EntityRef,
        percent: Decimal
    ) {
        self.owner = owner
        self.percent = percent
    }

    public var fraction: Decimal {
        percent > 1 ? (percent / 100) : percent
    }
}

public struct OwnershipChange: Codable, Sendable {
    public let state: OwnershipState
    public let divide: [OwnershipDivideEntry]

    public init(
        state: OwnershipState,
        divide: [OwnershipDivideEntry] = []
    ) {
        self.state = state
        self.divide = divide
    }

    // Compatibility passthroughs so older call-sites keep feeling natural.
    public var date: Date {
        state.date
    }

    public var percentage: Decimal {
        state.percentage
    }

    public var details: String? {
        state.details
    }
}

public struct OwnerEquity: Codable, Sendable {
    public let initial: OwnershipState
    public let changes: [OwnershipChange]

    public init(
        initial: OwnershipState,
        changes: [OwnershipChange]
    ) {
        self.initial = initial
        self.changes = changes.sorted { $0.date < $1.date }
    }

    public func state(
        on date: Date
    ) -> OwnershipState {
        let applicable = changes
            .filter { $0.date <= date }
            .sorted { $0.date < $1.date }
            .last

        return applicable?.state ?? initial
    }

    public func percentage(
        on date: Date
    ) -> Decimal {
        state(on: date).percentage
    }

    public func change(
        on date: Date
    ) -> OwnershipChange? {
        changes
            .filter { $0.date <= date }
            .sorted { $0.date < $1.date }
            .last
    }

    public func divideEntries(
        on date: Date
    ) -> [OwnershipDivideEntry] {
        change(on: date)?.divide ?? []
    }
}

public struct OwnershipSlice: Sendable {
    public let entityId: Int
    public let percent: Decimal

    public init(
        entityId: Int,
        percent: Decimal
    ) {
        self.entityId = entityId
        self.percent = percent
    }
}
