import Accounting
import Foundation

public struct EquityPeriod: Sendable {
    public let label: String
    public let bundle: StatementBundle
    public let asOf: Date
    public init(label: String, bundle: StatementBundle, asOf: Date) {
        self.label = label; self.bundle = bundle; self.asOf = asOf
    }
}
