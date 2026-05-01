import Accounting
import Foundation

public enum NativeBundleBuilder {
    public static func buildPeriodBundle(
        result: EntryCompileDriver.Result,
        kind: PeriodKind,
        anchor: Date,
        cut: AssembleCut,
        omslag: OmslagMode,
        entity: BusinessEntity = .vof,
        calendar: Calendar = periodCalendar()
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
        calendar: Calendar = periodCalendar()
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
            calendar: calendar
        )

        return assembled.current.bundle
    }
}
