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
        let indent: Int
        let label: String
        let amount: Decimal
        let isTotal: Bool

        init(
            indent: Int,
            label: String,
            amount: Decimal,
            isTotal: Bool = false
        ) {
            self.indent = indent
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
