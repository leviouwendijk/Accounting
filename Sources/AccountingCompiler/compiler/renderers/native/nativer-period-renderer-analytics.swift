import Accounting
import Foundation

extension NativePeriodRenderer {
    static func renderRatios(
        _ ratios: FinancialRatios?
    ) {
        guard let ratios else {
            return
        }

        let rows: [(String, String)] = [
            ("Solvabiliteit", formatNativeRatio(ratios.equityRatio, style: .percentage)),
            ("Schuldratio", formatNativeRatio(ratios.debtRatio, style: .percentage)),
            ("Debt-to-equity", formatNativeRatio(ratios.debtToEquity, style: .multiple)),
            ("Current ratio", formatNativeRatio(ratios.currentRatio, style: .multiple)),
            ("Quick ratio", formatNativeRatio(ratios.quickRatio, style: .multiple)),
            ("Gross margin", formatNativeRatio(ratios.grossMargin, style: .percentage)),
            ("Operating margin", formatNativeRatio(ratios.operatingMargin, style: .percentage)),
            ("Net margin", formatNativeRatio(ratios.netMargin, style: .percentage)),
            ("Equity multiplier", formatNativeRatio(ratios.equityMultiplier, style: .multiple)),
            ("ROA", formatNativeRatio(ratios.returnOnAssets, style: .percentage)),
            ("ROE", formatNativeRatio(ratios.returnOnEquity, style: .percentage)),
        ]

        let shown = rows.filter { $0.1 != "—" }
        guard !shown.isEmpty else {
            return
        }

        print("")
        print("Financiële ratio’s")
        print("──────────────────")

        for (label, value) in shown {
            print("- \(label): \(value)")
        }
    }

    static func renderAverages(
        _ averages: FinancialAverages?
    ) {
        guard let averages, !averages.isEmpty else {
            return
        }

        var rows: [(String, Decimal)] = []

        for metric in averages.metrics {
            for row in metric.rows {
                rows.append((
                    "\(metric.label) per \(averageUnitLabel(row.unit))",
                    row.value
                ))
            }
        }

        guard !rows.isEmpty else {
            return
        }

        print("")
        print("Gemiddeldes")
        print("───────────")

        for (label, value) in rows {
            print("- \(label): \(fmtDec(value))")
        }
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
    static func formatNativeRatio(
        _ value: Decimal?,
        style: StatementHTMLRenderer.RatioValueStyle
    ) -> String {
        guard let value else {
            return "—"
        }

        return StatementHTMLRenderer.formatRatio(
            value,
            style: style
        )
    }
}
