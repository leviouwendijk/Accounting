import Accounting
import AccountingCompiler
import Foundation

struct EntryCompilerCommandContext {
    var root: URL
    var settings: EntryCompilerSettings
    var result: EntryCompileDriver.Result
}

enum EntryCompilerCommandContextBuilder {
    static func build(
        project: ProjectOptions,
        trace: Bool,
        verbose: Bool = false
    ) async throws -> EntryCompilerCommandContext {
        let provided = URL(
            fileURLWithPath: project.resolvedPath,
            isDirectory: true
        )

        let root = EntryCompilerProject.findRoot(
            startingAt: provided
        ) ?? provided

        let settings = try EntryCompilerSettingsLoader.load(
            from: root,
            trace: trace
        )

        let compileSetting = CompileDriveSetting(
            entities: true,
            accounts: true,
            transactions: true,
            entries: true,
            assertion: true,
            loc_trace: trace
        )

        let result = try await EntryCompileDriver.compile(
            projectRoot: root,
            setting: compileSetting,
            verbose: verbose
        )

        return EntryCompilerCommandContext(
            root: root,
            settings: settings,
            result: result
        )
    }
}

enum EntryCompilerPeriodResolver {
    static func resolve(
        _ request: EntryCompilerPeriodRequest,
        timeZone: TimeZone
    ) throws -> ResolvedPeriodRequest {
        try PeriodSlicer.resolve(
            shape: request.shape,
            anchor: request.anchor,
            customFrom: request.from,
            customTo: request.to,
            defaultAnchor: Date(),
            timeZone: timeZone
        )
    }

    static func anchor(
        _ request: EntryCompilerPeriodRequest,
        timeZone: TimeZone
    ) throws -> ResolvedPeriodAnchorRequest {
        try PeriodSlicer.anchor(
            shape: request.shape,
            anchor: request.anchor,
            defaultAnchor: Date(),
            timeZone: timeZone
        )
    }
}
