import Foundation

public struct NativePeriodCompileOutput: Sendable {
    public let result: EntryCompileDriver.Result
    public let chart: CompiledChart
    public let shape: PeriodShape
    public let assembled: PeriodAssembleResult

    public init(
        result: EntryCompileDriver.Result,
        chart: CompiledChart,
        shape: PeriodShape,
        assembled: PeriodAssembleResult
    ) {
        self.result = result
        self.chart = chart
        self.shape = shape
        self.assembled = assembled
    }
}
