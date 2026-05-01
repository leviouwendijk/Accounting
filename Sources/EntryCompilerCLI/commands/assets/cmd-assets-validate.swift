import Accounting
import AccountingCompiler
import Arguments
import Foundation

enum AssetsValidateCommand: BoundArgumentCommand {
    typealias Options = AssetsValidateOptions

    static let name = "validate"

    static func run(
        _ options: AssetsValidateOptions,
        invocation: ParsedInvocation
    ) async throws {
        let context = try await EntryCompilerCommandContextBuilder.build(
            project: options.project,
            trace: options.trace
        )

        let report = try AssetViews.AssetValidationBuilder.build(
            result: context.result,
            tolerance: options.tolerance
        )

        print(
            AssetViews.AssetValidationPrinter.renderText(
                report,
                diagnostics: options.diagnostics,
                onlyFlagged: options.onlyFlagged
            )
        )
    }
}
