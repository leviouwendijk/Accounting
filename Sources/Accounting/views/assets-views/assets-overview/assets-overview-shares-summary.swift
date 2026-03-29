import Foundation

public struct AssetsOverviewVisibleSharesSummary: Sendable {
    public let breakdown: [AssetsOverviewOwnerShareAmounts]
    public let openingCarryingAmount: Decimal
    public let periodInvestment: Decimal
    public let closingCarryingAmount: Decimal

    public init(
        breakdown: [AssetsOverviewOwnerShareAmounts],
        openingCarryingAmount: Decimal,
        periodInvestment: Decimal,
        closingCarryingAmount: Decimal
    ) {
        self.breakdown = breakdown
        self.openingCarryingAmount = openingCarryingAmount
        self.periodInvestment = periodInvestment
        self.closingCarryingAmount = closingCarryingAmount
    }
}

public extension AssetViews {
    enum AssetsOverviewSharesSummary {
        public static func visible(
            from overview: AssetsOverview
        ) -> AssetsOverviewVisibleSharesSummary {
            var byOwner: [String: (
                openingCarryingAmount: Decimal,
                periodInvestment: Decimal,
                closingCarryingAmount: Decimal
            )] = [:]

            for group in overview.groups {
                if group.section == .unclassified {
                    continue
                }

                for item in group.totals.shareBreakdown {
                    var bucket = byOwner[item.ownerLabel] ?? (0, 0, 0)
                    bucket.openingCarryingAmount += item.openingCarryingAmount
                    bucket.periodInvestment += item.periodInvestment
                    bucket.closingCarryingAmount += item.closingCarryingAmount
                    byOwner[item.ownerLabel] = bucket
                }
            }

            let breakdown = byOwner.keys.sorted().map { ownerLabel in
                let bucket = byOwner[ownerLabel] ?? (0, 0, 0)

                return AssetsOverviewOwnerShareAmounts(
                    ownerLabel: ownerLabel,
                    openingCarryingAmount: bucket.openingCarryingAmount,
                    periodInvestment: bucket.periodInvestment,
                    closingCarryingAmount: bucket.closingCarryingAmount
                )
            }

            return AssetsOverviewVisibleSharesSummary(
                breakdown: breakdown,
                openingCarryingAmount: breakdown.reduce(0) { $0 + $1.openingCarryingAmount },
                periodInvestment: breakdown.reduce(0) { $0 + $1.periodInvestment },
                closingCarryingAmount: breakdown.reduce(0) { $0 + $1.closingCarryingAmount }
            )
        }
    }
}
