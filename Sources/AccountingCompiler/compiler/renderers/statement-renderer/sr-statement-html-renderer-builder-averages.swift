import Accounting
import Foundation

extension StatementHTMLRenderer {
    static func buildAveragesSection(
        from averages: FinancialAverages?
    ) -> AveragesSection? {
        guard let averages, !averages.isEmpty else {
            return nil
        }

        let rows: [AverageRow] = averages.metrics.flatMap { metric in
            metric.rows.map { row in
                AverageRow(
                    label: "\(metric.label) per \(averageUnitLabel(row.unit))",
                    description: averageDescription(for: row.unit),
                    value: row.value
                )
            }
        }

        guard !rows.isEmpty else {
            return nil
        }

        return AveragesSection(
            title: "Gemiddeldes",
            rows: rows
        )
    }

    @inline(__always)
    static func averageUnitLabel(
        _ unit: FinancialPeriodUnit
    ) -> String {
        switch unit {
        case .year:
            return "jaar"
        case .half:
            return "halfjaar"
        case .quarter:
            return "kwartaal"
        case .month:
            return "maand"
        case .week:
            return "week"
        case .day:
            return "dag"
        }
    }

    @inline(__always)
    static func averageDescription(
        for unit: FinancialPeriodUnit
    ) -> String {
        switch unit {
        case .year:
            return "Gemiddelde waarde omgerekend naar een jaarbasis."
        case .half:
            return "Gemiddelde waarde omgerekend naar een halfjaar."
        case .quarter:
            return "Gemiddelde waarde omgerekend naar een kwartaal."
        case .month:
            return "Gemiddelde waarde omgerekend naar een maand."
        case .week:
            return "Gemiddelde waarde omgerekend naar een week."
        case .day:
            return "Gemiddelde waarde omgerekend naar een dag."
        }
    }
}
