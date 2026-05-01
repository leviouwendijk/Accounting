import Accounting
import Foundation

public struct EffectiveEquityBreakdownRow: Sendable {
    public let label: String
    public let allocation: EffectiveEquityAllocation
    public let total: Decimal

    public init(
        label: String,
        allocation: EffectiveEquityAllocation,
        total: Decimal
    ) {
        self.label = label
        self.allocation = allocation
        self.total = total
    }
}

public func buildEffectiveEquityBreakdownRow(
    label: String,
    directByOwner: [Int: Decimal],
    asOf: Date,
    entities: EntityStore,
    names: [Int?: String]
) throws -> EffectiveEquityBreakdownRow {
    let amounts = Dictionary(
        uniqueKeysWithValues: directByOwner.map { ownerId, value in
            (
                ownerId,
                EquityOwnerAmounts(
                    begin: 0,
                    stort: 0,
                    onttrek: value,
                    winst: 0,
                    end: value
                )
            )
        }
    )

    let allocation = try buildEffectiveEquityAllocation(
        directByOwner: amounts,
        asOf: asOf,
        entities: entities,
        names: names
    )

    let total = directByOwner.values.reduce(0, +)

    return .init(
        label: label,
        allocation: allocation,
        total: total
    )
}
