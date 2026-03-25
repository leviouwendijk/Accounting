import Foundation

public enum KIAShareInputMode: String, Codable, Sendable, Hashable {
    case percentage
    case amount
}

public struct KIAOwnerShare: Codable, Sendable, Hashable {
    public let owner: EntityRef
    public let percentage: Decimal
    public let amount: Decimal

    public init(
        owner: EntityRef,
        percentage: Decimal,
        amount: Decimal
    ) {
        self.owner = owner
        self.percentage = percentage
        self.amount = amount
    }
}

public struct KIAConfigAssetAllocation: Codable, Sendable, Hashable {
    public let mode: KIAShareInputMode
    public let shares: [KIAOwnerShare]

    public init(
        mode: KIAShareInputMode,
        shares: [KIAOwnerShare]
    ) {
        self.mode = mode
        self.shares = shares
    }
}

public struct KIAOwnerShareDraft: Codable, Sendable, Hashable {
    public let owner: EntityRef
    public let value: Decimal

    public init(
        owner: EntityRef,
        value: Decimal
    ) {
        self.owner = owner
        self.value = value
    }
}

public struct KIADraft: Codable, Sendable, Hashable {
    public let mode: KIAShareInputMode
    public let shares: [KIAOwnerShareDraft]

    public init(
        mode: KIAShareInputMode,
        shares: [KIAOwnerShareDraft]
    ) {
        self.mode = mode
        self.shares = shares
    }

    public func resolve(
        acquisitionCost: Decimal,
        tolerance: Decimal = 0.01
    ) throws -> KIAConfigAssetAllocation {
        guard acquisitionCost > 0 else {
            throw KIAResolutionError.invalidAcquisitionCost(acquisitionCost)
        }

        guard !shares.isEmpty else {
            throw KIAResolutionError.emptyShares
        }

        switch mode {
        case .percentage:
            let totalPct = shares.reduce(Decimal(0)) { $0 + $1.value }
            if decimalMagnitude(totalPct - 100) > tolerance {
                throw KIAResolutionError.invalidPercentageTotal(totalPct)
            }

            let resolved = shares.map { share in
                let pct = share.value
                let amt = acquisitionCost * pct / 100
                return KIAOwnerShare(
                    owner: share.owner,
                    percentage: pct,
                    amount: amt
                )
            }

            return KIAConfigAssetAllocation(
                mode: .percentage,
                shares: resolved
            )

        case .amount:
            let totalAmount = shares.reduce(Decimal(0)) { $0 + $1.value }
            if decimalMagnitude(totalAmount - acquisitionCost) > tolerance {
                throw KIAResolutionError.invalidAmountTotal(
                    totalAmount: totalAmount,
                    acquisitionCost: acquisitionCost
                )
            }

            let resolved = shares.map { share in
                let amt = share.value
                let pct = (amt / acquisitionCost) * 100
                return KIAOwnerShare(
                    owner: share.owner,
                    percentage: pct,
                    amount: amt
                )
            }

            return KIAConfigAssetAllocation(
                mode: .amount,
                shares: resolved
            )
        }
    }

    @inline(__always)
    private func decimalMagnitude(_ value: Decimal) -> Decimal {
        value < 0 ? -value : value
    }
}

public enum KIAResolutionError: LocalizedError, Sendable {
    case emptyShares
    case invalidAcquisitionCost(Decimal)
    case invalidPercentageTotal(Decimal)
    case invalidAmountTotal(totalAmount: Decimal, acquisitionCost: Decimal)

    public var errorDescription: String? {
        switch self {
        case .emptyShares:
            return "KIA shares block cannot be empty."
        case .invalidAcquisitionCost(let cost):
            return "KIA share resolution requires positive acquisition cost; got \(cost)."
        case .invalidPercentageTotal(let total):
            return "KIA percentage shares must total 100.00; got \(total)."
        case .invalidAmountTotal(let totalAmount, let acquisitionCost):
            return "KIA amount shares must total the acquisition cost; got \(totalAmount) vs \(acquisitionCost)."
        }
    }
}
