import Accounting
import Arguments
import Foundation

struct EquityCommandOptions: Sendable, ArgumentParsed {
    typealias ArgumentPayload = Options

    var project: ProjectOptions
    var period: EntryCompilerPeriodRequest
    var history: Bool
    var compare: Bool
    var byEntity: Bool
    var pdf: Bool
    var trace: Bool
    var useAsync: Bool

    init(
        arguments: Options
    ) throws {
        self.project = arguments.project
        self.period = try EntryCompilerPeriodRequest(
            arguments: arguments.period
        )
        self.history = arguments.history
        self.compare = arguments.compare
        self.byEntity = arguments.byEntity
        self.pdf = arguments.pdf
        self.trace = arguments.trace
        self.useAsync = arguments.useAsync
    }

    struct Options: ArgumentGroup {
        @Group("project")
        var project: ProjectOptions

        @Group("period")
        var period: EntryCompilerPeriodRequest.MonthOptions

        @Flag("history")
        var history: Bool

        @Flag("compare")
        var compare: Bool

        @Flag("by-entity")
        var byEntity: Bool

        @Flag("pdf")
        var pdf: Bool

        @Flag("trace")
        var trace: Bool

        @Flag("async")
        var useAsync: Bool

        init() {}
    }
}
