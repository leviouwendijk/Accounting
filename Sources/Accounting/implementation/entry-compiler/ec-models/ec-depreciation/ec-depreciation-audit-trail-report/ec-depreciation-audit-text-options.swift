import Foundation

public struct DepreciationAuditTextOptions: Sendable, Codable {
    public var title: String = "Depreciation audit"
    public var underline: String = "──────────────────"
    public var showHeader: Bool = true
    public var onlyFailures: Bool = true
    public var maxFailureDetailLines: Int = 6
    public var showAllGoodLine: Bool = true     // prints "• all good" when there are no failures
    public var useISODateOnly: Bool = true      // ISO date without time
    public var includeSummaryBlock: Bool = true // periods checked / exact / within tol / aggregate covered / failures
    public var fractionDigits: Int? = 2

    public init() {}
}
