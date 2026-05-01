import Accounting
import AccountingCompiler
import Arguments
import Foundation

enum CompileCommand: ParsedArgumentCommand {
    typealias Options = CompileOptions

    static let name = "compile"

    static let children: [ArgumentCommandType] = [
        CompilePeriodCommand.self,
        CompileEquityCommand.self,
    ]

    static func run(
        _ options: CompileOptions,
        invocation: ParsedInvocation
    ) async throws {
        let context = try await EntryCompilerCommandContextBuilder.build(
            project: options.project,
            trace: options.trace,
            verbose: options.verbose
        )

        if options.verbose {
            let withMistakes = context
                .result
                .entries
                .enumerated()
                .filter { $0.element.mistake != nil }

            if !withMistakes.isEmpty {
                print("\nParsed entries with mistakes (\(withMistakes.count)):")

                for (_, entry) in withMistakes {
                    let idString = entry.id.map {
                        "#\($0)"
                    } ?? "(no id)"

                    print("— Entry \(idString)\(entry.location.describeSuffix):")
                    print(entry.viewableString)
                    print()
                }
            }
        }

        do {
            let native = try NativeOutputBuilder.buildCompileOutput(
                result: context.result,
                cut: AssembleCut(
                    target: .L3,
                    includeCodes: [
                        "BLimBanRba",
                        "WOmzNopOlh",
                    ],
                    includeIntermediates: true,
                    omitZerosBeyondLevel1: true
                ),
                omslag: .apply,
                entity: .vof,
                autoClose: true
            )

            let projectionKind = try EntryCompilerProjection.resolve(
                taxonomy: options.projection.taxonomy,
                presentation: options.projection.presentation,
                projectionDiagnostics: options.projection.projectionDiagnostics
            )

            try ProjectionPipeline.render(
                native,
                as: projectionKind,
                options: NativeRenderOptions(
                    caption: options.presentation.caption,
                    detail: options.presentation.detail,
                    equityCode: "BEiv",
                    includeOtherBucket: false,
                    comparePrevious: false,
                    showRangeHeading: true
                ),
                showProjectionDiagnostics: options.projection.projectionDiagnostics
            )
        } catch {
            fputs(
                "warning: assembler output failed: \(error)\n",
                stderr
            )
        }
    }
}

enum CompilePeriodCommand: ParsedArgumentCommand {
    typealias Options = PeriodCommandOptions

    static let name = "period"

    static func run(
        _ options: PeriodCommandOptions,
        invocation: ParsedInvocation
    ) async throws {
        try await PeriodCommandRunner.run(
            options
        )
    }
}

enum CompileEquityCommand: ParsedArgumentCommand {
    typealias Options = EquityCommandOptions

    static let name = "equity"

    static func run(
        _ options: EquityCommandOptions,
        invocation: ParsedInvocation
    ) async throws {
        try await EquityCommandRunner.run(
            options
        )
    }
}
