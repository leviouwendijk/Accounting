import Foundation

public struct CoverageIssue: Sendable {
    public let accountCode: String
    public let rgs: String
    public let omslag: String?
    public let amount: Decimal
    public let dims: DimensionSlice
}
