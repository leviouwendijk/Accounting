import Foundation

extension StatementHTMLRenderer {
    struct DocumentModel: Sendable {
        let income: TableSection
        let balances: [TableSection]
        let summary: BalanceSummary?

        init(
            income: TableSection,
            balances: [TableSection],
            summary: BalanceSummary?
        ) {
            self.income = income
            self.balances = balances
            self.summary = summary
        }
    }

    struct TableSection: Sendable {
        let title: String
        let rows: [TableRow]
        let subtotal: Decimal?

        init(
            title: String,
            rows: [TableRow],
            subtotal: Decimal? = nil
        ) {
            self.title = title
            self.rows = rows
            self.subtotal = subtotal
        }
    }

    struct TableRow: Sendable {
        let id: Int?
        let parentId: Int?
        let depth: Int
        let prefix: String
        let label: String
        let amount: Decimal
        let isTotal: Bool

        init(
            id: Int? = nil,
            parentId: Int? = nil,
            depth: Int,
            prefix: String = "",
            label: String,
            amount: Decimal,
            isTotal: Bool = false
        ) {
            self.id = id
            self.parentId = parentId
            self.depth = depth
            self.prefix = prefix
            self.label = label
            self.amount = amount
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
