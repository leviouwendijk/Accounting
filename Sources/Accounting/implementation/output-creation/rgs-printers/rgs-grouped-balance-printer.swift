import Foundation

@available(*, deprecated, message: "Use RGSPrinter.balanceSectionsByL2Ordered + RGSPrinter.printSectionsWithFooters")
public func printGroupedBalance(
    _ title: String,
    bundle: StatementBundle,
    chart: CompiledChart
) throws {
    let sections = try RGSPrinter.balanceSectionsByL2Ordered(from: bundle, using: chart)
    try RGSPrinter.printSectionsWithFooters(title, sections: sections, chart: chart, bundle: bundle, omslag: .apply)
}
