import Foundation

public struct TrialBalance: Sendable {
    public let perAccount: [Int: LedgerBucket]       // account code -> totals
    public let totalDebits: Decimal
    public let totalCredits: Decimal
}
