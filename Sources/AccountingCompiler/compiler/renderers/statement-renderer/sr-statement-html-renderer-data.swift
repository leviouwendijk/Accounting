import Accounting
import Foundation

extension StatementHTMLRenderer {
    struct DocumentModel: Sendable {
        let income: TableSection
        let balances: [TableSection]
        let summary: BalanceSummary?
        let ratios: RatiosSection?
        let averages: AveragesSection?

        init(
            income: TableSection,
            balances: [TableSection],
            summary: BalanceSummary?,
            ratios: RatiosSection?,
            averages: AveragesSection?
        ) {
            self.income = income
            self.balances = balances
            self.summary = summary
            self.ratios = ratios
            self.averages = averages
        }
    }


    struct RatiosSection: Sendable {
        let title: String
        let rows: [RatioRow]

        init(
            title: String,
            rows: [RatioRow]
        ) {
            self.title = title
            self.rows = rows
        }
    }

    struct RatioRow: Sendable {
        let label: String
        let description: String?
        let formula: String?
        let value: Decimal?
        let style: RatioValueStyle
        
        public init(
            label: String,
            description: String? = nil,
            formula: String? = nil,
            value: Decimal?,
            style: RatioValueStyle
        ) {
            self.label = label
            self.description = description
            self.formula = formula
            self.value = value
            self.style = style
        }
    }

    enum RatioValueStyle: Sendable {
        case percentage
        case multiple
    }

    struct AveragesSection: Sendable {
        let title: String
        let rows: [AverageRow]

        init(
            title: String,
            rows: [AverageRow]
        ) {
            self.title = title
            self.rows = rows
        }
    }

    struct AverageRow: Sendable {
        let label: String
        let description: String?
        let value: Decimal?

        init(
            label: String,
            description: String? = nil,
            value: Decimal?
        ) {
            self.label = label
            self.description = description
            self.value = value
        }
    }

    enum TableSectionKind: Sendable {
        case incomeStatement
        case balance(BalanceSectionKind)
    }

    enum BalanceSectionKind: Sendable {
        case assets
        case equity
        case liabilities
        case other
    }

    struct TableSection: Sendable {
        let kind: TableSectionKind
        let title: String
        let rows: [TableRow]
        let subtotal: Decimal?

        init(
            kind: TableSectionKind,
            title: String,
            rows: [TableRow],
            subtotal: Decimal? = nil
        ) {
            self.kind = kind
            self.title = title
            self.rows = rows
            self.subtotal = subtotal
        }

        var shouldStartOnNewPrintPage: Bool {
            switch kind {
            case .incomeStatement:
                return false

            case .balance(.assets):
                return true

            case .balance(.equity):
                return true

            case .balance(.liabilities):
                return false

            case .balance(.other):
                return false
            }
        }

        var sectionClassName: String {
            switch kind {
            case .incomeStatement:
                return "sr-section sr-section-income"

            case .balance(.assets):
                return "sr-section sr-section-balance sr-section-balance-assets"

            case .balance(.equity):
                return "sr-section sr-section-balance sr-section-balance-equity"

            case .balance(.liabilities):
                return "sr-section sr-section-balance sr-section-balance-liabilities"

            case .balance(.other):
                return "sr-section sr-section-balance sr-section-balance-other"
            }
        }

        var renderedSectionClassName: String {
            if shouldStartOnNewPrintPage {
                return sectionClassName + " sr-print-page-break-before"
            }

            return sectionClassName
        }
    }

    struct TableRow: Sendable {
        let id: Int?
        let parentId: Int?
        let depth: Int
        let prefix: String
        let label: String
        let amount: Decimal
        let direction: Direction
        let orientation: AccountOrientation
        let isTotal: Bool

        init(
            id: Int? = nil,
            parentId: Int? = nil,
            depth: Int,
            prefix: String = "",
            label: String,
            amount: Decimal,
            direction: Direction,
            orientation: AccountOrientation,
            isTotal: Bool = false
        ) {
            self.id = id
            self.parentId = parentId
            self.depth = depth
            self.prefix = prefix
            self.label = label
            self.amount = amount
            self.direction = direction
            self.orientation = orientation
            self.isTotal = isTotal
        }
    }

    struct BalanceSummary: Sendable {
        let assets: Decimal
        let equity: Decimal
        let liabilities: Decimal

        init(
            assets: Decimal,
            equity: Decimal,
            liabilities: Decimal
        ) {
            self.assets = assets
            self.equity = equity
            self.liabilities = liabilities
        }

        var equityPlusLiabilities: Decimal {
            equity + liabilities
        }

        var diff: Decimal {
            assets - equityPlusLiabilities
        }

        var isBalanced: Bool {
            assets == equityPlusLiabilities
        }
    }
}
