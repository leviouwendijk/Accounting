import Foundation

public enum StatementType {
    case income // income = revenue - expenses - dividends
    case balance // assets = liabilities + equity
    case cashFlow // simplified cash flow: operating, investing, financing
}

public class StatementNode {
    public let code: String?
    public let label: String
    public let balance: Double
    public var children: [StatementNode]

    public init(code: String? = nil, label: String, balance: Double, children: [StatementNode] = []) {
        self.code = code
        self.label = label
        self.balance = balance
        self.children = children
    }
}

public struct RGSStatements {
    /// first build the raw tree of BalanceNode
    public static func buildTree(accounts: [RGSAccount], raw: [String: Double]) -> [BalanceNode] {
        compileBalanceTree(accounts: accounts, rawBalances: raw)
    }

    /// income statement
    public static func incomeStatement(
        from tree: [BalanceNode]
    ) -> StatementNode {
        let rev  = tree.filter { $0.account.accountClass == AccountClass.revenue }
        let exp  = tree.filter { $0.account.accountClass == AccountClass.expense }
        let div  = tree.filter { $0.account.accountClass == AccountClass.dividend }

        func mk(_ label: String, _ nodes: [BalanceNode]) -> StatementNode {
            let sum = nodes.reduce(0) { $0 + $1.balance }
            return StatementNode(label: label, balance: sum, children:
                nodes.map { n in
                    StatementNode(code: n.account.code,
                                  label: n.account.label,
                                  balance: n.balance)
                }
            )
        }

        let revN = mk("Revenue",  rev)
        let expN = mk("Expenses", exp)
        let divN = mk("Dividends", div)
        let net  = revN.balance - expN.balance - divN.balance

        let root = StatementNode(label: "Income Statement", balance: net, children: [
            revN, expN, divN,
            StatementNode(label: "Net Profit", balance: net)
        ])
        return root
    }

    /// balance sheet
    public static func balanceSheet(
        from tree: [BalanceNode]
    ) -> StatementNode {
        let ast = tree.filter { $0.account.accountClass == AccountClass.asset }
        let lib = tree.filter { $0.account.accountClass == AccountClass.liability }
        let eq  = tree.filter { $0.account.accountClass == AccountClass.equity }

        func mk(_ title: String, _ nodes: [BalanceNode]) -> StatementNode {
            let sum = nodes.reduce(0) { $0 + $1.balance }
            let kids = nodes.map { n in
                StatementNode(code: n.account.code,
                              label: n.account.label,
                              balance: n.balance,
                              children: n.children.map {
                                  StatementNode(code: $0.account.code,
                                                label: $0.account.label,
                                                balance: $0.balance)
                              })
            }
            return StatementNode(label: title, balance: sum, children: kids)
        }

        let a = mk("Assets",       ast)
        let l = mk("Liabilities",  lib)
        let e = mk("Equity",       eq)
        let diff = a.balance - (l.balance + e.balance)

        return StatementNode(label: "Balance Sheet",
                             balance: a.balance,
                             children: [
                                a, l, e,
                                StatementNode(label: "Diff (A - L - E)",
                                              balance: diff)
                             ])
    }

    /// cash-flow
    public static func cashFlowStatement(
        fromRawTree tree: [BalanceNode]
    ) -> StatementNode {
        let inc = incomeStatement(from: tree)
        let bs  = balanceSheet(from: tree)

        // op = net profit
        let op = StatementNode(label: "Operating Activities",
                               balance: inc.balance,
                               children: inc.children)

        // inv: long-term assets = codes 2000..<8000
        let assetsSection = bs.children.first { $0.label == "Assets" }!
        let invKids = assetsSection.children.filter {
            if let code = $0.code, let v = Int(code) { return (2000..<8000).contains(v) }
            return false
        }
        let invSum = invKids.reduce(0) { $0 + $1.balance }
        let inv = StatementNode(label: "Investing Activities",
                                balance: invSum,
                                children: invKids)

        // fin: equity movements
        let eqSection = bs.children.first { $0.label == "Equity" }!
        let fin = StatementNode(label: "Financing Activities",
                                balance: eqSection.balance,
                                children: eqSection.children)

        return StatementNode(label: "Cash Flow Statement",
                             balance: 0,
                             children: [op, inv, fin])
    }
}
