import Accounting
import Arguments
import Foundation

struct CompileOptions: Sendable, ArgumentParsed {
    typealias ArgumentPayload = Options

    var project: ProjectOptions
    var snapshotsDir: String
    var verbose: Bool
    var trace: Bool
    var presentation: PresentationOptions
    var projection: ProjectionOptionsWithDiagAlias

    init(
        arguments: Options
    ) throws {
        self.project = arguments.project
        self.snapshotsDir = arguments.snapshotsDir
        self.verbose = arguments.verbose
        self.trace = arguments.trace
        self.presentation = arguments.presentation
        self.projection = arguments.projection
    }

    struct Options: ArgumentGroup {
        @Group("project")
        var project: ProjectOptions

        @Opt(
            "snapshots-dir",
            default: "_snapshots"
        )
        var snapshotsDir: String

        @Flag(
            "verbose",
            short: "v"
        )
        var verbose: Bool

        @Flag("trace")
        var trace: Bool

        @Group("presentation")
        var presentation: PresentationOptions

        @Group("projection")
        var projection: ProjectionOptionsWithDiagAlias

        init() {}
    }
}
