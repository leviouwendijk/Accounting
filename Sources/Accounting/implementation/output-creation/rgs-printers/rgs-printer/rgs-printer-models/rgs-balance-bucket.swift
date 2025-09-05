import Foundation

public struct RGSBalanceBucketsOutput: Sendable {
    public struct Line: Sendable {
        public let id: Int
        public let code: String
        public let label: String
        public let amount: Decimal
        public let level: Int
        public let relativeIndent: Int
    }
    public struct Section: Sendable {
        public let title: String               // "Assets" | "Equity" | "Liabilities" | "Other"
        public let lines: [Line]
        public let subtotal: Decimal?          // from analytics.l2Totals when available
    }
    public let assets: Section?
    public let equity: Section?
    public let liabilities: Section?
    public let other: Section?
    public let summary: (assets: Decimal, equity: Decimal, liabilities: Decimal)?
}
