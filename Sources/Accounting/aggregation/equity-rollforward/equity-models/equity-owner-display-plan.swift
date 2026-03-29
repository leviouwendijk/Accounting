import Foundation

public struct EquityOwnerDisplayPlan: Sendable {
    public let rows: [EquityOwnerDisplayRowSpec]

    public init(
        rows: [EquityOwnerDisplayRowSpec]
    ) {
        self.rows = rows
    }
}

public enum EquityOwnerDisplayRowSpec: Sendable {
    case owner(EntityRef)
    case composed(EquityOwnerComposedRow)
}

public struct EquityOwnerComposedRow: Sendable {
    public let label: String
    public let members: [EquityOwnerPortion]
    public let style: EquityOwnerDisplayStyle

    public init(
        label: String,
        members: [EquityOwnerPortion],
        style: EquityOwnerDisplayStyle = .subtotal
    ) {
        self.label = label
        self.members = members
        self.style = style
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

    static func subtotal(
        label: String,
        owners: [EntityRef]
    ) -> Self {
        .composed(
            .init(
                label: label,
                members: owners.map {
                    EquityOwnerPortion(
                        owner: $0,
                        portion: 1
                    )
                },
                style: .subtotal
            )
        )
    }

    static func split(
        label: String,
        owner: EntityRef,
        percent: Decimal,
        style: EquityOwnerDisplayStyle = .subtotal
    ) -> Self {
        .composed(
            .init(
                label: label,
                members: [
                    .init(
                        owner: owner,
                        portion: percent
                    )
                ],
                style: style
            )
        )
    }

    static func composed(
        label: String,
        members: [EquityOwnerPortion],
        style: EquityOwnerDisplayStyle = .subtotal
    ) -> Self {
        .composed(
            .init(
                label: label,
                members: members,
                style: style
            )
        )
    }
}
