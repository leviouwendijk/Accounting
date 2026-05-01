import Accounting
import Foundation

public extension RGSAssembler {
    static func summarizeBalanceSides(
        chart: CompiledChart,
        bundle: StatementBundle,
        bounds: AlphaBounds = .default
    ) throws -> BalanceAlphaSections {
        let maps = try RGSAssembler.makeMaps(from: chart)
        return try RGSAssembler.balanceAlphaSections(
            totals: bundle.totalsById,
            maps: maps,
            bounds: bounds
        )
    }
    // keep printing out of assembler layer
    // /// Prints A/J/K summary and returns the underlying values.
    // /// Returns both the alpha-band sections (leaf-based) and a BalanceEquation for assertions.
    // @discardableResult
    // static func printedBalances(
    //     chart: CompiledChart,
    //     bundle: StatementBundle,
    //     bounds: AlphaBounds = .default,
    //     omslag: OmslagMode = .apply
    // ) throws -> (alpha: BalanceAlphaSections, equation: BalanceEquation) {
    //     let maps  = try RGSAssembler.makeMaps(from: chart)
    //     let alpha = try RGSAssembler.balanceAlphaSections(
    //         totals: bundle.totalsById,
    //         maps: maps,
    //         bounds: bounds
    //     )
    //     let eq = BalanceEquation(
    //         assets:      ("A*", -1, alpha.assets),
    //         equity:      ("J*", -1, alpha.equity),
    //         liabilities: ("K*", -1, alpha.liabilities)
    //     )
    //     try RGSAssembler.assertBalanced(eq)
    //     RGSPrinter.printBalanceSidesSummary(
    //         title: "Balance Sections (summary)",
    //         equation: eq,
    //         maps: maps,
    //         omslag: omslag
    //     )
    //     return (alpha, eq)
    // }
}
