import Accounting
import Foundation
import HTML

public enum StatementHTMLRenderer {}

extension StatementHTMLRenderer {
    public static func render(
        period: PeriodAssembleResultPeriod,
        chart: CompiledChart,
        equityCode: String = "BEiv",
        options: Options = .init()
    ) throws -> String {
        var opts = options
        opts.subtitle = period.range.string()

        return try render(
            bundle: period.bundle,
            chart: chart,
            equityCode: equityCode,
            options: opts
        )
    }

    public static func render(
        bundle: StatementBundle,
        chart: CompiledChart,
        equityCode: String = "BEiv",
        options: Options = .init()
    ) throws -> String {
        let model = try buildDocumentModel(
            bundle: bundle,
            chart: chart,
            equityCode: equityCode,
            options: options
        )

        return renderDocument(
            model: model,
            options: options
        )
    }
}
