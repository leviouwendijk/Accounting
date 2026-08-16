import Accounting
import AccountingCompiler
import Foundation

extension VATCommand {
    static func resolvePeriod(
        _ request: VATPeriodRequest,
        settings: EntryCompilerSettings
    ) throws -> ResolvedPeriodRequest {
        try PeriodSlicer.resolve(
            shape: request.shape,
            anchor: request.anchor,
            customFrom: request.from,
            customTo: request.to,
            defaultAnchor: EntryCompilerDefaults.vat.anchor(
                for: request,
                timeZone: settings.entry.defaultTimezone
            ),
            timeZone: settings.entry.defaultTimezone
        )
    }

    static func makePeriodLabel(
        request: VATPeriodRequest,
        period: ResolvedPeriodRequest,
        settings: EntryCompilerSettings,
        calendar: Calendar
    ) -> String {
        EntryCompilerLabels.vat(
            kind: request.kind,
            shape: period.effectiveShape,
            anchor: period.anchor,
            window: period.windows.window,
            calendar: calendar
        )
    }

    static func makeVATSlug(
        request: VATPeriodRequest,
        period: ResolvedPeriodRequest,
        settings: EntryCompilerSettings,
        calendar: Calendar
    ) -> String {
        EntryCompilerSlugs.vat(
            kind: request.kind,
            shape: period.effectiveShape,
            anchor: period.anchor,
            window: period.windows.window,
            timeZone: settings.entry.defaultTimezone,
            calendar: calendar
        )
    }

    static func writePDF(
        root: URL,
        filename: String,
        html: String,
        margins: Double
    ) async throws {
        try await EntryCompilerPDFWriter.write(
            root: root,
            filename: filename,
            html: html,
            margins: margins
        )
    }
}
