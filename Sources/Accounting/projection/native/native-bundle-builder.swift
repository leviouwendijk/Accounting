import Foundation

public enum NativeBundleBuilder {
    public static func buildPeriodBundle(
        result: EntryCompileDriver.Result,
        kind: PeriodKind,
        anchor: Date,
        cut: AssembleCut,
        omslag: OmslagMode,
        entity: BusinessEntity = .vof,
        tz: TimeZone = .current,
        calendar: Calendar = {
            var c = Calendar(identifier: .iso8601)
            c.firstWeekday = 2
            return c
        }()
    ) throws -> StatementBundle {
        let assembled = try PeriodAssembler.assemble(
            shape: .init(
                kind: kind,
                rangeToDate: false
            ),
            anchor: anchor,
            result: result,
            cut: cut,
            omslag: omslag,
            entity: entity,
            tz: tz,
            calendar: calendar
        )

        return assembled.current.bundle
    }

    public static func buildPeriodBundleAsync(
        result: EntryCompileDriver.Result,
        kind: PeriodKind,
        anchor: Date,
        cut: AssembleCut,
        omslag: OmslagMode,
        entity: BusinessEntity = .vof,
        tz: TimeZone = .current,
        calendar: Calendar = {
            var c = Calendar(identifier: .iso8601)
            c.firstWeekday = 2
            return c
        }()
    ) async throws -> StatementBundle {
        let assembled = try await PeriodAssembler.assemble_concurrent(
            shape: .init(
                kind: kind,
                rangeToDate: false
            ),
            anchor: anchor,
            result: result,
            cut: cut,
            omslag: omslag,
            entity: entity,
            tz: tz,
            calendar: calendar
        )

        return assembled.current.bundle
    }
}
