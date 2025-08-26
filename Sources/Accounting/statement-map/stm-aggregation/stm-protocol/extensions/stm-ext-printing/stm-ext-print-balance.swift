import Foundation

public extension StatementAggregating {
    func totalsForBalance(cube: StatementCube, statement: StatementDef, periodIndex: Int) -> (assets: Decimal, liab: Decimal, eq: Decimal) {
        func sumRow(_ idRaw: String) -> Decimal {
            let id = StatementRowId(raw: idRaw)
            return cube.reduce(0) { partial, kv in
                kv.key.periodIndex == periodIndex && kv.key.row == id ? partial + kv.value : partial
            }
        }
        let assets = sumRow("assets")
        let liab   = sumRow("liabilities")
        let eq     = sumRow("equity")
        return (assets, liab, eq)
    }

    func printBalanceCheck(cube: StatementCube, statement: StatementDef, periodIndex: Int = 0) {
        // Assets (debit-natured) shown as +; Liab & Equity (credit-natured) shown as +
        let assets =  sumRow(cube, "assets", periodIndex)                  // debit -> show as-is
        let liab   = -sumRow(cube, "liabilities", periodIndex)             // credit -> flip sign
        let equity = -sumRow(cube, "equity", periodIndex)                  // credit -> flip sign

        let rhs  = liab + equity
        let diff = assets - rhs

        FileHandle.standardError.write(Data(
            ("Check: Assets (\(fmt(assets))) vs Liab+Equity (\(fmt(rhs))) → Diff \(fmt(diff))\n").utf8
        ))
    }
}
