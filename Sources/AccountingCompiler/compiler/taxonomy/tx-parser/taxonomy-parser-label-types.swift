import Accounting
import Foundation

public struct TaxonomyLabelArc: Sendable, Hashable {
    public let from: String
    public let to: String

    public init(
        from: String,
        to: String
    ) {
        self.from = from
        self.to = to
    }
}
