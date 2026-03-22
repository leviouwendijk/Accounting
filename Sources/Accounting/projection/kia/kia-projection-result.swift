import Foundation

public struct KIAProjectionResult: Sendable {
    public let taxYear: Int
    public let qualifyingInvestmentTotal: Decimal
    public let deduction: Decimal
    public let qualifiedAssets: [KIAQualifiedAsset]
    public let excludedAssets: [KIAExcludedAsset]

    public init(
        taxYear: Int,
        qualifyingInvestmentTotal: Decimal,
        deduction: Decimal,
        qualifiedAssets: [KIAQualifiedAsset],
        excludedAssets: [KIAExcludedAsset]
    ) {
        self.taxYear = taxYear
        self.qualifyingInvestmentTotal = qualifyingInvestmentTotal
        self.deduction = deduction
        self.qualifiedAssets = qualifiedAssets
        self.excludedAssets = excludedAssets
    }
}
