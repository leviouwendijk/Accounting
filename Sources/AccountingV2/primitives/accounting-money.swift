 import Foundation

public enum AccountingMoney {
    public static let currencyScale = 2

    @inline(__always)
    public static func round(
        _ value: Decimal,
        scale: Int = AccountingMoney.currencyScale,
        mode: NSDecimalNumber.RoundingMode = .plain
    ) -> Decimal {
        var input = value
        var output = Decimal()
        NSDecimalRound(&output, &input, scale, mode)
        return output
    }
}
