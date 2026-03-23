import Foundation

// public struct DepreciationAuditTextOptions: Sendable, Codable {
//     public var title: String = "Depreciation audit"
//     public var underline: String = "──────────────────"
//     public var showHeader: Bool = true
//     public var onlyFailures: Bool = true
//     public var maxFailureDetailLines: Int = 6
//     public var showAllGoodLine: Bool = true     // prints "• all good" when there are no failures
//     public var useISODateOnly: Bool = true      // ISO date without time
//     public var includeSummaryBlock: Bool = true // periods checked / exact / within tol / aggregate covered / failures
//     public var fractionDigits: Int? = 2

//     public init() {}
// }

public struct DepreciationAuditTextOptions: Sendable {
    public var title: String
    public var underline: String

    public var showHeader: Bool
    public var includeSummaryBlock: Bool
    public var showFailuresEvenIfCovered: Bool

    public var fractionDigits: Int?
    public var useISODateOnly: Bool

    public var showPerYearAmounts: Bool
    public var showPerMonthAmounts: Bool
    public var showPerPeriodAmounts: Bool

    public init(
        title: String = "Depreciation audit",
        underline: String = "──────────────────",
        showHeader: Bool = true,
        includeSummaryBlock: Bool = true,
        showFailuresEvenIfCovered: Bool = false,
        fractionDigits: Int? = 2,
        useISODateOnly: Bool = true,
        showPerYearAmounts: Bool = true,
        showPerMonthAmounts: Bool = true,
        showPerPeriodAmounts: Bool = false
    ) {
        self.title = title
        self.underline = underline
        self.showHeader = showHeader
        self.includeSummaryBlock = includeSummaryBlock
        self.showFailuresEvenIfCovered = showFailuresEvenIfCovered
        self.fractionDigits = fractionDigits
        self.useISODateOnly = useISODateOnly
        self.showPerYearAmounts = showPerYearAmounts
        self.showPerMonthAmounts = showPerMonthAmounts
        self.showPerPeriodAmounts = showPerPeriodAmounts
    }
}
