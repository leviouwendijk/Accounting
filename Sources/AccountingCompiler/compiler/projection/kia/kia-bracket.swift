import Accounting
import Foundation

public struct KIABracket: Sendable, Hashable {
    public let lowerInclusive: Decimal
    public let upperInclusive: Decimal?
    public let fixedDeduction: Decimal?
    public let rate: Decimal?
    public let baseAmount: Decimal?

    public init(
        lowerInclusive: Decimal,
        upperInclusive: Decimal?,
        fixedDeduction: Decimal?,
        rate: Decimal?,
        baseAmount: Decimal?
    ) {
        self.lowerInclusive = lowerInclusive
        self.upperInclusive = upperInclusive
        self.fixedDeduction = fixedDeduction
        self.rate = rate
        self.baseAmount = baseAmount
    }
}
