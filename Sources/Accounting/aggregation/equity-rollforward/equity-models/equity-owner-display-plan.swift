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

    public init(
        owner: EntityRef,
        portion: Decimal,
        label: String? = nil
    ) {
        self.owner = owner
        self.portion = portion
        self.label = label
    }
}

public struct EquityOwnerSubtotalRow: Sendable {
    public let label: String
    public let members: [EquityOwnerPortion]

    public init(
        label: String,
        members: [EquityOwnerPortion]
    ) {
        self.label = label
        self.members = members
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
        label: String? = nil
    ) -> Self {
        .split(
            .init(
                owner: owner,
                portion: percent,
                label: label
            )
        )
    }

    static func subtotal(
        label: String,
        members: [EquityOwnerPortion]
    ) -> Self {
        .subtotal(
            .init(
                label: label,
                members: members
            )
        )
    }
}
