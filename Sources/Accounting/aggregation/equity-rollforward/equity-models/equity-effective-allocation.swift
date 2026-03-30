import Foundation

public struct EquityOwnerAmounts: Sendable, Equatable {
    public let begin: Decimal
    public let stort: Decimal
    public let onttrek: Decimal
    public let winst: Decimal
    public let end: Decimal

    public init(
        begin: Decimal,
        stort: Decimal,
        onttrek: Decimal,
        winst: Decimal,
        end: Decimal
    ) {
        self.begin = begin
        self.stort = stort
        self.onttrek = onttrek
        self.winst = winst
        self.end = end
    }

    public static let zero = EquityOwnerAmounts(
        begin: 0,
        stort: 0,
        onttrek: 0,
        winst: 0,
        end: 0
    )

    public static func + (
        lhs: EquityOwnerAmounts,
        rhs: EquityOwnerAmounts
    ) -> EquityOwnerAmounts {
        .init(
            begin: lhs.begin + rhs.begin,
            stort: lhs.stort + rhs.stort,
            onttrek: lhs.onttrek + rhs.onttrek,
            winst: lhs.winst + rhs.winst,
            end: lhs.end + rhs.end
        )
    }

    public static func - (
        lhs: EquityOwnerAmounts,
        rhs: EquityOwnerAmounts
    ) -> EquityOwnerAmounts {
        .init(
            begin: lhs.begin - rhs.begin,
            stort: lhs.stort - rhs.stort,
            onttrek: lhs.onttrek - rhs.onttrek,
            winst: lhs.winst - rhs.winst,
            end: lhs.end - rhs.end
        )
    }

    public static func * (
        lhs: EquityOwnerAmounts,
        rhs: Decimal
    ) -> EquityOwnerAmounts {
        .init(
            begin: lhs.begin * rhs,
            stort: lhs.stort * rhs,
            onttrek: lhs.onttrek * rhs,
            winst: lhs.winst * rhs,
            end: lhs.end * rhs
        )
    }
}

public enum EffectiveEquityBranchKind: Sendable {
    case direct
    case incoming
    case outgoing
}

public struct EffectiveEquityBranch: Sendable {
    public let kind: EffectiveEquityBranchKind
    public let sourceOwnerId: Int?
    public let targetOwnerId: Int?
    public let label: String
    public let detail: String?
    public let amounts: EquityOwnerAmounts

    public init(
        kind: EffectiveEquityBranchKind,
        sourceOwnerId: Int?,
        targetOwnerId: Int?,
        label: String,
        detail: String?,
        amounts: EquityOwnerAmounts
    ) {
        self.kind = kind
        self.sourceOwnerId = sourceOwnerId
        self.targetOwnerId = targetOwnerId
        self.label = label
        self.detail = detail
        self.amounts = amounts
    }
}

public struct EffectiveEquityOwnerNode: Sendable {
    public let ownerId: Int
    public let ownerName: String
    public let direct: EquityOwnerAmounts
    public let incoming: [EffectiveEquityBranch]
    public let outgoing: [EffectiveEquityBranch]
    public let primary: EquityOwnerAmounts

    public init(
        ownerId: Int,
        ownerName: String,
        direct: EquityOwnerAmounts,
        incoming: [EffectiveEquityBranch],
        outgoing: [EffectiveEquityBranch],
        primary: EquityOwnerAmounts
    ) {
        self.ownerId = ownerId
        self.ownerName = ownerName
        self.direct = direct
        self.incoming = incoming
        self.outgoing = outgoing
        self.primary = primary
    }
}

public struct EffectiveEquityAllocation: Sendable {
    public let ownerIds: [Int]
    public let nodes: [EffectiveEquityOwnerNode]

    public init(
        ownerIds: [Int],
        nodes: [EffectiveEquityOwnerNode]
    ) {
        self.ownerIds = ownerIds
        self.nodes = nodes
    }
}
