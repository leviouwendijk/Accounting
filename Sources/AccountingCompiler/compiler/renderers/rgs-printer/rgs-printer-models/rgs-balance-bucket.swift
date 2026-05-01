import Accounting
import Foundation

public struct RGSBalanceBucketsOutput: Sendable {
    public struct Line: Sendable {
        public let id: Int
        public let code: String
        public let label: String
        public let rawAmount: Decimal
        public let amount: Decimal
        public let level: Int
        public let relativeIndent: Int
        public let direction: Direction
        public let orientation: AccountOrientation

        public init(
            id: Int,
            code: String,
            label: String,
            rawAmount: Decimal,
            amount: Decimal,
            level: Int,
            relativeIndent: Int,
            direction: Direction,
            orientation: AccountOrientation
        ) {
            self.id = id
            self.code = code
            self.label = label
            self.rawAmount = rawAmount
            self.amount = amount
            self.level = level
            self.relativeIndent = relativeIndent
            self.direction = direction
            self.orientation = orientation
        }
    }

    public struct Section: Sendable {
        public let title: String
        public let lines: [Line]
        public let subtotal: Decimal?

        public init(
            title: String,
            lines: [Line],
            subtotal: Decimal?
        ) {
            self.title = title
            self.lines = lines
            self.subtotal = subtotal
        }
    }

    public let assets: Section?
    public let equity: Section?
    public let liabilities: Section?
    public let other: Section?
    public let summary: (assets: Decimal, equity: Decimal, liabilities: Decimal)?

    public init(
        assets: Section?,
        equity: Section?,
        liabilities: Section?,
        other: Section?,
        summary: (assets: Decimal, equity: Decimal, liabilities: Decimal)?
    ) {
        self.assets = assets
        self.equity = equity
        self.liabilities = liabilities
        self.other = other
        self.summary = summary
    }
}

// public struct RGSBalanceBucketsOutput: Sendable {
//     public struct Line: Sendable {
//         public let id: Int
//         public let code: String
//         public let label: String
//         public let amount: Decimal
//         public let level: Int
//         public let relativeIndent: Int
//     }
//     public struct Section: Sendable {
//         public let title: String               // "Assets" | "Equity" | "Liabilities" | "Other"
//         public let lines: [Line]
//         public let subtotal: Decimal?          // from analytics.l2Totals when available
//     }
//     public let assets: Section?
//     public let equity: Section?
//     public let liabilities: Section?
//     public let other: Section?
//     public let summary: (assets: Decimal, equity: Decimal, liabilities: Decimal)?
// }
