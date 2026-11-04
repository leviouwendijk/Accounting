import AccountingV2
import AccountingV2Fixtures
import Arguments
import Foundation

@main
enum EntryCompilerV2Command: ArgumentCommand {
    static let name = "ec_v2"
    static let defaultChild = V2CompileCommand.self

    static let children: [ArgumentCommandType] = [
        V2CompileCommand.self,
        V2PeriodCommand.self,
        V2ContinuityCommand.self,
        V2WindowsCommand.self,
        V2PositionsCommand.self,
        V2BoundedCommand.self,
        V2ComparativeCommand.self
    ]
}

enum V2PeriodCommand: ParsedArgumentCommand {
    typealias Options = V2PeriodOptions
    static let name = "period"

    static func run(
        _ options: V2PeriodOptions,
        invocation: ParsedInvocation
    ) async throws {
        try V2CommandRunner.runPeriod(options)
    }
}

enum V2WindowsCommand: ParsedArgumentCommand {
    typealias Options = V2WindowsOptions
    static let name = "windows"

    static func run(
        _ options: V2WindowsOptions,
        invocation: ParsedInvocation
    ) async throws {
        try V2CommandRunner.runWindows(options)
    }
}

enum V2PositionsCommand: ParsedArgumentCommand {
    typealias Options = V2WindowsOptions
    static let name = "positions"

    static func run(
        _ options: V2WindowsOptions,
        invocation: ParsedInvocation
    ) async throws {
        try V2CommandRunner.runPositions(options)
    }
}

struct V2ContinuityOptions: ArgumentParsed, Sendable {
    typealias ArgumentPayload = Payload

    init(arguments: Payload) throws {}

    struct Payload: ArgumentGroup {
        init() {}
    }
}

enum V2ContinuityCommand: ParsedArgumentCommand {
    typealias Options = V2ContinuityOptions

    static let name = "continuity"

    static func run(
        _ options: V2ContinuityOptions,
        invocation: ParsedInvocation
    ) async throws {
        try V2CommandRunner.runContinuity()
    }
}

enum V2BoundedCommand: ParsedArgumentCommand {
    typealias Options = V2ContinuityOptions
    static let name = "bounded"

    static func run(
        _ options: V2ContinuityOptions,
        invocation: ParsedInvocation
    ) async throws {
        try V2CommandRunner.runBounded()
    }
}

enum V2ComparativeCommand: ParsedArgumentCommand {
    typealias Options = V2ContinuityOptions
    static let name = "comparative"

    static func run(
        _ options: V2ContinuityOptions,
        invocation: ParsedInvocation
    ) async throws {
        try V2CommandRunner.runComparative()
    }
}

enum V2CompileCommand: ParsedArgumentCommand {
    typealias Options = V2CompileOptions
    static let name = "compile"

    static func run(
        _ options: V2CompileOptions,
        invocation: ParsedInvocation
    ) async throws {
        try V2CommandRunner.runCompile(options)
    }
}
