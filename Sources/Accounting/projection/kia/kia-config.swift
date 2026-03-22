import Foundation

public struct KIAConfig: Sendable, Hashable {
    public let countryCode: String
    public let taxYear: Int
    public let minimumInvestmentTotal: Decimal
    public let minimumAssetAmount: Decimal
    public let brackets: [KIABracket]

    public init(
        countryCode: String,
        taxYear: Int,
        minimumInvestmentTotal: Decimal,
        minimumAssetAmount: Decimal,
        brackets: [KIABracket]
    ) {
        self.countryCode = countryCode
        self.taxYear = taxYear
        self.minimumInvestmentTotal = minimumInvestmentTotal
        self.minimumAssetAmount = minimumAssetAmount
        self.brackets = brackets
    }
}
