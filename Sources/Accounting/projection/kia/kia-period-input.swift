import Foundation

public struct KIAPeriodInput: Sendable, Hashable {
    public let taxYear: Int

    public init(taxYear: Int) {
        self.taxYear = taxYear
    }
}
