import Foundation

public struct ResolvedPeriodRequest: Sendable {
    public let requestedShape: PeriodShape
    public let effectiveShape: PeriodShape

    public let anchor: Date
    public let customFrom: Date?
    public let customTo: Date?

    public let windows: PeriodWindows

    public init(
        requestedShape: PeriodShape,
        effectiveShape: PeriodShape,
        anchor: Date,
        customFrom: Date?,
        customTo: Date?,
        windows: PeriodWindows
    ) {
        self.requestedShape = requestedShape
        self.effectiveShape = effectiveShape
        self.anchor = anchor
        self.customFrom = customFrom
        self.customTo = customTo
        self.windows = windows
    }

    public var usesCustomRange: Bool {
        customFrom != nil || customTo != nil
    }
}
