import Accounting
import Foundation

public struct IBVOFOverview: Sendable, SectionedPresentableOutput {
    public struct Row: Sendable {
        public let field: IBVOFField
        public let label: String
        public let amount: Decimal
        public let sourceCodes: [String]
        public let derived: Bool
        public let note: String?

        public init(
            field: IBVOFField,
            label: String,
            amount: Decimal,
            sourceCodes: [String] = [],
            derived: Bool = false,
            note: String? = nil
        ) {
            self.field = field
            self.label = label
            self.amount = amount
            self.sourceCodes = sourceCodes
            self.derived = derived
            self.note = note
        }
    }

    public struct Section: Sendable {
        public let key: String
        public let title: String
        public let rows: [Row]

        public init(
            key: String,
            title: String,
            rows: [Row]
        ) {
            self.key = key
            self.title = title
            self.rows = rows
        }
    }

    public struct Summary: Sendable {
        public let label: String
        public let amount: Decimal

        public init(
            label: String,
            amount: Decimal
        ) {
            self.label = label
            self.amount = amount
        }
    }

    public let title: String
    public let sections: [Section]
    public let summaries: [Summary]

    public init(
        title: String,
        sections: [Section],
        summaries: [Summary] = []
    ) {
        self.title = title
        self.sections = sections
        self.summaries = summaries
    }
}
