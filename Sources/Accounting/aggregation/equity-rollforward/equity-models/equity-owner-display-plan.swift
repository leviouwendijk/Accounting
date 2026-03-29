import Foundation

public struct EquityOwnerDisplayPlan: Sendable {
    public let sections: [EquityOwnerDisplaySection]

    public init(
        sections: [EquityOwnerDisplaySection]
    ) {
        self.sections = sections
    }
}

public struct EquityOwnerDisplaySection: Sendable {
    public let rows: [EquityOwnerDisplayRowSpec]

    public init(
        rows: [EquityOwnerDisplayRowSpec]
    ) {
        self.rows = rows
    }
}

public enum EquityOwnerDisplayRowSpec: Sendable {
    case owner(EntityRef)
    case split(EquityOwnerSplitRow)
    case subtotal(EquityOwnerSubtotalRow)
}

public struct EquityOwnerSplitRow: Sendable {
    public let owner: EntityRef
    public let portion: Decimal
    public let label: String?
    public let includeInSum: Bool

    public init(
        owner: EntityRef,
        portion: Decimal,
        label: String? = nil,
        includeInSum: Bool = true
    ) {
        self.owner = owner
        self.portion = portion
        self.label = label
        self.includeInSum = includeInSum
    }
}

public struct EquityOwnerSubtotalRow: Sendable {
    public let label: String
    public let members: [EquityOwnerPortion]
    public let includeInSum: Bool

    public init(
        label: String,
        members: [EquityOwnerPortion],
        includeInSum: Bool = true
    ) {
        self.label = label
        self.members = members
        self.includeInSum = includeInSum
    }
}

public struct EquityOwnerPortion: Sendable {
    public let owner: EntityRef
    public let portion: Decimal

    public init(
        owner: EntityRef,
        portion: Decimal
    ) {
        self.owner = owner
        self.portion = portion
    }
}

public enum EquityOwnerDisplayStyle: String, Sendable, Codable {
    case normal
    case subtotal
}

public extension EquityOwnerDisplayRowSpec {
    static func wholeOwner(
        _ owner: EntityRef
    ) -> Self {
        .owner(owner)
    }

    static func split(
        owner: EntityRef,
        percent: Decimal,
        label: String? = nil,
        includeInSum: Bool = true
    ) -> Self {
        .split(
            .init(
                owner: owner,
                portion: percent,
                label: label,
                includeInSum: includeInSum
            )
        )
    }

    static func subtotal(
        label: String,
        members: [EquityOwnerPortion],
        includeInSum: Bool = true
    ) -> Self {
        .subtotal(
            .init(
                label: label,
                members: members,
                includeInSum: includeInSum
            )
        )
    }
}
