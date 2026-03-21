import Foundation

extension TaxonomyShared {
    public static func decimalString(
        _ value: Decimal
    ) -> String {
        let number = NSDecimalNumber(decimal: value)

        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "_"
        formatter.maximumFractionDigits = 8
        formatter.minimumFractionDigits = 0

        return formatter.string(from: number) ?? number.stringValue
    }
}
