import Foundation

extension StatementHTMLRenderer {
    enum ComparativeAmountCell: Sendable {
        case value(Decimal)
        case blank
    }

    struct ComparativeAmountColumn: Sendable {
        let title: String

        init(
            title: String
        ) {
            self.title = title
        }
    }

    struct ComparativeDocumentModel: Sendable {
        let income: ComparativeSection
        let balances: [ComparativeSection]
        let summary: BalanceSummary?
        let ratios: RatiosSection?

        init(
            income: ComparativeSection,
            balances: [ComparativeSection],
            summary: BalanceSummary?,
            ratios: RatiosSection?
        ) {
            self.income = income
            self.balances = balances
            self.summary = summary
            self.ratios = ratios
        }
    }

    struct ComparativeSection: Sendable {
        let kind: TableSectionKind
        let title: String
        let columns: [ComparativeAmountColumn]
        let rows: [ComparativeRow]
        let subtotalCells: [ComparativeAmountCell]

        init(
            kind: TableSectionKind,
            title: String,
            columns: [ComparativeAmountColumn],
            rows: [ComparativeRow],
            subtotalCells: [ComparativeAmountCell]
        ) {
            self.kind = kind
            self.title = title
            self.columns = columns
            self.rows = rows
            self.subtotalCells = subtotalCells
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

    struct ComparativeRow: Sendable {
        let id: Int?
        let parentId: Int?
        let depth: Int
        let prefix: String
        let label: String
        let cells: [ComparativeAmountCell]
        let direction: Direction
        let orientation: AccountOrientation
        let isTotal: Bool

        init(
            id: Int? = nil,
            parentId: Int? = nil,
            depth: Int,
            prefix: String = "",
            label: String,
            cells: [ComparativeAmountCell],
            direction: Direction,
            orientation: AccountOrientation,
            isTotal: Bool = false
        ) {
            self.id = id
            self.parentId = parentId
            self.depth = depth
            self.prefix = prefix
            self.label = label
            self.cells = cells
            self.direction = direction
            self.orientation = orientation
            self.isTotal = isTotal
        }
    }
}
