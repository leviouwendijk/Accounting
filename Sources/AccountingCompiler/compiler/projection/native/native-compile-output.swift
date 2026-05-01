import Accounting
import Foundation

public struct NativeCompileOutput: Sendable {
    public let result: EntryCompileDriver.Result
    public let chart: CompiledChart
    public let bundle: StatementBundle

    public init(
        result: EntryCompileDriver.Result,
        chart: CompiledChart,
        bundle: StatementBundle
    ) {
        self.result = result
        self.chart = chart
        self.bundle = bundle
    }
}
