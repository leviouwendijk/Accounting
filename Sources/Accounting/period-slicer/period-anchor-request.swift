import Foundation

public struct ResolvedPeriodAnchorRequest: Sendable {
    public let shape: PeriodShape
    public let anchor: Date

    public init(
        shape: PeriodShape,
        anchor: Date
    ) {
        self.shape = shape
        self.anchor = anchor
    }
}
