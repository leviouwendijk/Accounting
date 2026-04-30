import Accounting
import Arguments
import Foundation

struct AssetsOverviewOptions: Sendable, ArgumentParsed {
    typealias ArgumentPayload = Options

    var project: ProjectOptions
    var period: EntryCompilerPeriodRequest
    var pdf: PDFOptions
    var diagnostics: Bool
    var trace: Bool

    init(
        arguments: Options
    ) throws {
        self.project = arguments.project
        self.period = try EntryCompilerPeriodRequest(
            arguments: arguments.period
        )
        self.pdf = arguments.pdf
        self.diagnostics = arguments.diagnostics
        self.trace = arguments.trace
    }

    struct Options: ArgumentGroup {
        @Group("project")
        var project: ProjectOptions

        @Group("period")
        var period: EntryCompilerPeriodRequest.Options

        @Group("pdf")
        var pdf: PDFOptions

        @Flag("diagnostics")
        var diagnostics: Bool

        @Flag("trace")
        var trace: Bool

        init() {}
    }
}

struct AssetsAcquiredOptions: Sendable, ArgumentParsed {
    typealias ArgumentPayload = Options

    var project: ProjectOptions
    var period: EntryCompilerPeriodRequest
    var diagnostics: Bool
    var trace: Bool

    init(
        arguments: Options
    ) throws {
        self.project = arguments.project
        self.period = try EntryCompilerPeriodRequest(
            arguments: arguments.period
        )
        self.diagnostics = arguments.diagnostics
        self.trace = arguments.trace
    }

    struct Options: ArgumentGroup {
        @Group("project")
        var project: ProjectOptions

        @Group("period")
        var period: EntryCompilerPeriodRequest.Options

        @Flag("diagnostics")
        var diagnostics: Bool

        @Flag("trace")
        var trace: Bool

        init() {}
    }
}

struct AssetsValidateOptions: Sendable, ArgumentGroup {
    @Group("project")
    var project: ProjectOptions

    @Opt(
        "tolerance",
        default: 0
    )
    var tolerance: Decimal

    @Flag("diagnostics")
    var diagnostics: Bool

    @Flag("only-flagged")
    var onlyFlagged: Bool

    @Flag("trace")
    var trace: Bool

    init() {}
}

struct AssetsSharesOptions: Sendable, ArgumentParsed {
    typealias ArgumentPayload = Options

    var project: ProjectOptions
    var period: EntryCompilerPeriodRequest
    var history: Bool
    var pdf: PDFOptions
    var trace: Bool

    init(
        arguments: Options
    ) throws {
        self.project = arguments.project
        self.period = try EntryCompilerPeriodRequest(
            arguments: arguments.period
        )
        self.history = arguments.history
        self.pdf = arguments.pdf
        self.trace = arguments.trace
    }

    struct Options: ArgumentGroup {
        @Group("project")
        var project: ProjectOptions

        @Group("period")
        var period: EntryCompilerPeriodRequest.Options

        @Flag("history")
        var history: Bool

        @Group("pdf")
        var pdf: PDFOptions

        @Flag("trace")
        var trace: Bool

        init() {}
    }
}
