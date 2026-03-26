import Foundation

public enum DecimalFuncs {
    @inline(__always)
    public static func absDec(
        _ value: Decimal
    ) -> Decimal {
        value < 0 ? -value : value
    }
}
