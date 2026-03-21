import Foundation

public struct NativeRenderOptions: Sendable {
    public let caption: String
    public let detail: String
    public let equityCode: String
    public let includeOtherBucket: Bool
    public let comparePrevious: Bool
    public let showRangeHeading: Bool
    public let showEntityBreakdown: Bool

    public init(
        caption: String = "label",
        detail: String = "standard",
        equityCode: String = "BEiv",
        includeOtherBucket: Bool = false,
        comparePrevious: Bool = true,
        showRangeHeading: Bool = true,
        showEntityBreakdown: Bool = false,
    ) {
        self.caption = caption
        self.detail = detail
        self.equityCode = equityCode
        self.includeOtherBucket = includeOtherBucket
        self.comparePrevious = comparePrevious
        self.showRangeHeading = showRangeHeading
        self.showEntityBreakdown = showEntityBreakdown
    }
}
