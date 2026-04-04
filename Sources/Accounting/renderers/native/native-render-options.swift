import Foundation

public struct NativeRenderOptions: Sendable {
    public var caption: String
    public var detail: String
    public var equityCode: String
    public var includeOtherBucket: Bool
    public var comparePrevious: Bool
    public var showRangeHeading: Bool
    public var showEntityBreakdown: Bool
    public var periodShape: PeriodShape?

    public init(
        caption: String = "label",
        detail: String = "standard",
        equityCode: String = "BEiv",
        includeOtherBucket: Bool = false,
        comparePrevious: Bool = true,
        showRangeHeading: Bool = true,
        showEntityBreakdown: Bool = false,
        periodShape: PeriodShape? = nil
    ) {
        self.caption = caption
        self.detail = detail
        self.equityCode = equityCode
        self.includeOtherBucket = includeOtherBucket
        self.comparePrevious = comparePrevious
        self.showRangeHeading = showRangeHeading
        self.showEntityBreakdown = showEntityBreakdown
        self.periodShape = periodShape
    }
}
