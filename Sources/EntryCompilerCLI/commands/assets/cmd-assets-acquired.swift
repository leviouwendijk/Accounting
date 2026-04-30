import Accounting
import Arguments
import Foundation

enum AssetsAcquiredCommand: ParsedArgumentCommand {
    typealias Options = AssetsAcquiredOptions

    static let name = "acquired"

    static func run(
        _ options: AssetsAcquiredOptions,
        invocation: ParsedInvocation
    ) async throws {
        let context = try await EntryCompilerCommandContextBuilder.build(
            project: options.project,
            trace: options.trace
        )

        let period = try EntryCompilerPeriodResolver.resolve(
            options.period,
            timeZone: context.settings.entry.defaultTimezone
        )

        let calendar = periodCalendar(
            timeZone: context.settings.entry.defaultTimezone
        )

        let report = try AssetViews.AcquiredAssetsBuilder.build(
            result: context.result,
            period: period.windows.window,
            anchor: period.anchor,
            calendar: calendar
        )

        print(
            AssetViews.AcquiredAssetsPrinter.renderText(
                report,
                diagnostics: options.diagnostics
            )
        )
    }
}
