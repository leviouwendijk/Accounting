import Foundation

public struct VATOverview: Sendable {
    public struct Row: Sendable {
        public let id: Int
        public let level: Int
        public let label: String
        public let code: String
        public let amount: Decimal
        public init(id: Int, level: Int, label: String, code: String, amount: Decimal) {
            self.id = id; self.level = level; self.label = label; self.code = code; self.amount = amount
        }
    }

    public struct Section: Sendable {
        public let title: String
        public let rows: [Row]
        public init(title: String, rows: [Row]) {
            self.title = title; self.rows = rows
        }
    }

    public struct Summary: Sendable {
        public let label: String
        public let code: String?   // nil for derived totals like net position
        public let amount: Decimal
        public init(label: String, code: String?, amount: Decimal) {
            self.label = label; self.code = code; self.amount = amount
        }
    }

    public let title: String
    public let sections: [Section]
    public let summaries: [Summary]
    public let netPosition: Decimal?  // (te betalen) − (te vorderen), if both present

    public init(title: String, sections: [Section], summaries: [Summary], netPosition: Decimal?) {
        self.title = title
        self.sections = sections
        self.summaries = summaries
        self.netPosition = netPosition
    }
}
