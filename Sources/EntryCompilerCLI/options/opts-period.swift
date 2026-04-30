import Accounting
import Arguments
import Foundation

struct PeriodCommandOptions: Sendable, ArgumentParsed {
    typealias ArgumentPayload = Options

    var project: ProjectOptions
    var period: EntryCompilerPeriodRequest
    var compare: Bool
    var byEntity: Bool
    var pdf: PDFOptions
    var trace: Bool
    var presentation: PresentationOptions
    var projection: ProjectionOptions
    var analyticsDiagnostics: Bool
    var hierarchyDiagnostics: Bool

    init(
        arguments: Options
    ) throws {
        self.project = arguments.project
        self.period = try EntryCompilerPeriodRequest(
            arguments: arguments.period
        )
        self.compare = arguments.compare
        self.byEntity = arguments.byEntity
        self.pdf = arguments.pdf
        self.trace = arguments.trace
        self.presentation = arguments.presentation
        self.projection = arguments.projection
        self.analyticsDiagnostics = arguments.analyticsDiagnostics
        self.hierarchyDiagnostics = arguments.hierarchyDiagnostics
    }

    struct Options: ArgumentGroup {
        @Group("project")
        var project: ProjectOptions

        @Group("period")
        var period: EntryCompilerPeriodRequest.MonthOptions

        @Flag("compare")
        var compare: Bool

        @Flag("by-entity")
        var byEntity: Bool

        @Group("pdf")
        var pdf: PDFOptions

        @Flag("trace")
        var trace: Bool

        @Group("presentation")
        var presentation: PresentationOptions

        @Group("projection")
        var projection: ProjectionOptions

        @Flag(
            "analytics-diagnostics",
            alias: "diag"
        )
        var analyticsDiagnostics: Bool

        @Flag("hierarchy-diagnostics")
        var hierarchyDiagnostics: Bool

        init() {}
    }
}
