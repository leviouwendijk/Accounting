import Accounting
import Foundation

public extension PeriodAssembler {
    @inline(__always)
    static func buildChart(from result: EntryCompileDriver.Result) throws -> CompiledChart {
        let nodes = Array(result.accounts.byCode.values)
        return try CompiledChart(
            name: "Project RGS",
            version: .init(major: 0, minor: 0),
            nodes: nodes
        ) // ensures index + enriched parents
    }
}
