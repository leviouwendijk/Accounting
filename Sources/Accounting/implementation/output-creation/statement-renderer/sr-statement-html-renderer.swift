import Foundation

public enum StatementHTMLRenderer {
    public struct Options: Sendable {
        public var title: String = "Financial Statements"
        public var subtitle: String? = nil  
        public var currencySymbol: String = "€"
        public var minAbsIncome: Decimal = 0
        public var includeOtherBucket: Bool = false
        public var omitIncomeLevel1Root: Bool = true

        public init(
            title: String = "Financial Statements",
            subtitle: String? = nil,
            currencySymbol: String = "€",
            minAbsIncome: Decimal = 0,
            includeOtherBucket: Bool = false,
            omitIncomeLevel1Root: Bool = true
        ) {
            self.title = title
            self.subtitle = subtitle
            self.currencySymbol = currencySymbol
            self.minAbsIncome = minAbsIncome
            self.includeOtherBucket = includeOtherBucket
            self.omitIncomeLevel1Root = omitIncomeLevel1Root
        }
    }

    public static func render(
        period: PeriodAssembleResultPeriod,
        chart: CompiledChart,
        equityCode: String = "BEiv",
        options: Options = .init()
    ) throws -> String {
        var opts = options
        // PeriodWindow already provides a nice human formatter:
        // e.g. "Period: 1 Jan 2025 → 31 Jan 2025"
        opts.subtitle = period.range.string()   // <- uses PeriodWindow.string()
        return try render(bundle: period.bundle, chart: chart, equityCode: equityCode, options: opts)
    }

    public static func render(
        bundle: StatementBundle,
        chart: CompiledChart,
        equityCode: String = "BEiv",
        options: Options = .init()
    ) throws -> String {

        let sections = try RGSPrinter.computeBalanceByL2Sections(
            bundle: bundle, chart: chart,
            equityCode: equityCode, includeOtherBucket: options.includeOtherBucket
        )

        func escape(_ s: String) -> String {
            s.replacingOccurrences(of: "&", with: "&amp;")
             .replacingOccurrences(of: "<", with: "&lt;")
             .replacingOccurrences(of: ">", with: "&gt;")
        }
        func fmt(_ d: Decimal) -> String {
            let nf = NumberFormatter()
            nf.locale = Locale(identifier: "nl_NL")  // tweak if you prefer en_US
            nf.numberStyle = .decimal
            nf.minimumFractionDigits = 2
            nf.maximumFractionDigits = 2
            return nf.string(from: d as NSDecimalNumber) ?? d.description
        }

        func table(for title: String, rows: [(indent: Int, label: String, amount: Decimal, isTotal: Bool)]) -> String {
            var h = "<h2>\(escape(title))</h2>\n<table class='tbl'>"
            h += "<thead><tr><th class='col-label'>Label</th><th class='col-amt'>Amount</th></tr></thead><tbody>"
            for r in rows {
                let pad = String(repeating: "&nbsp;&nbsp;", count: max(0, r.indent))
                let lbl = r.isTotal ? "<strong>\(escape(r.label))</strong>" : escape(r.label)
                let amt = r.isTotal ? "<strong>\(fmt(r.amount))</strong>" : fmt(r.amount)
                h += "<tr><td class='label'>\(pad)\(lbl)</td><td class='amt'>\(amt)</td></tr>"
            }
            h += "</tbody></table>"
            return h
        }

        let subtitleHTML = options.subtitle.map { "<div class=\"subtitle\">\(escape($0))</div>" } ?? ""

        var html = """
        <html>
        <head>
          <meta charset="utf-8">
          <title>\(escape(options.title))</title>
          <style>
            body { font: 14px -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; margin: 24px; }
            h1 { margin: 0 0 6px 0; }
            .subtitle { color: #666; margin-bottom: 16px; }
            h2 { margin-top: 24px; border-bottom: 1px solid #ddd; padding-bottom: 4px; }
            table.tbl { width: 100%; border-collapse: collapse; margin-top: 8px; }
            .tbl thead th { text-align: left; font-weight: 600; font-size: 12px; color: #666; }
            .tbl td { padding: 2px 0; border-bottom: 1px dotted #eee; vertical-align: top; }
            .tbl .col-amt, .tbl .amt { text-align: right; width: 20%; }
            .tbl .label { white-space: nowrap; }
            .summary { margin-top: 8px; color: #444; }
            .ok    { color: #0a7a28; }
            .warn  { color: #b05a00; }
          </style>
        </head>
        <body>
          <h1>\(escape(options.title))</h1>
          \(subtitleHTML)
        """

        // 4a) Winst- en verliesrekening via secties (Opbrengsten/Kosten), zonder L1 kop
        let isSections = try RGSPrinter.incomeSections(bundle: bundle, chart: chart)

        // Localize section titles
        func nlTitle(for key: String) -> String {
            switch key {
            case "revenue":  return "Opbrengsten"
            case "expenses": return "Kosten"
            default:         return "Overig"
            }
        }

        // Helpers
        @inline(__always)
        func subtotal(_ lines: [RGSPresentationLine]) -> Decimal {
            lines.reduce(0) { $0 + $1.amount }   // amounts already sign-adjusted by .apply
        }
        @inline(__always)
        func toRows(_ lines: [RGSPresentationLine]) -> [(Int,String,Decimal,Bool)] {
            lines
                .filter { options.minAbsIncome == 0 ? true : ($0.amount.magnitude >= options.minAbsIncome) }
                // start indent at L2 = 0
                .map { (indent: max(0, Int($0.level) - 2), label: $0.label, amount: $0.amount, isTotal: false) }
        }

        // Build section tables
        let revSec = isSections.first(where: { $0.key == "revenue" })
        let expSec = isSections.first(where: { $0.key == "expenses" })
        let othSec = isSections.first(where: { $0.key == "other" })

        if let s = revSec {
            var rows = toRows(s.lines)
            rows.append((0, "Subtotaal \(nlTitle(for: s.key))", subtotal(s.lines), true))
            html += table(for: "Winst- en Verliesrekening — \(nlTitle(for: s.key))", rows: rows)
        }
        if let s = expSec {
            var rows = toRows(s.lines)
            rows.append((0, "Subtotaal \(nlTitle(for: s.key))", subtotal(s.lines), true))
            html += table(for: "Winst- en Verliesrekening — \(nlTitle(for: s.key))", rows: rows)
        }
        if let s = othSec, !s.lines.isEmpty {
            var rows = toRows(s.lines)
            rows.append((0, "Subtotaal \(nlTitle(for: s.key))", subtotal(s.lines), true))
            html += table(for: "Winst- en Verliesrekening — \(nlTitle(for: s.key))", rows: rows)
        }

        // Net result (expenses are negative after .apply)
        let totalRevenue  = revSec.map { subtotal($0.lines) } ?? 0
        let totalExpenses = expSec.map { subtotal($0.lines) } ?? 0
        let netResult     = totalRevenue + totalExpenses

        html += table(for: "Resultaat (winst/verlies)", rows: [
            (0, "Resultaat", netResult, true)
        ])


        // 4b) Balance Sheet (Assets / Equity / Liabilities in separate tables; “Other” optional)
        func rows(for sec: RGSBalanceBucketsOutput.Section?) -> [(Int,String,Decimal,Bool)] {
            guard let s = sec else { return [] }
            var rs = s.lines.map { (indent: $0.relativeIndent, label: $0.label, amount: $0.amount, isTotal: false) }
            if let st = s.subtotal {
                rs.append((indent: 0, label: "Som", amount: st, isTotal: true))
                // rs.append((indent: 0, label: "Subtotal \(s.title)", amount: st, isTotal: true))
            }
            return rs
        }
        // html += table(for: "Balance Sheet — Assets",      rows: rows(for: sections.assets))
        // html += table(for: "Balance Sheet — Equity",      rows: rows(for: sections.equity))
        // html += table(for: "Balance Sheet — Liabilities", rows: rows(for: sections.liabilities))

        html += table(for: "Balans: Activa",      rows: rows(for: sections.assets))
        html += table(for: "Balans: Eigen Vermogen",      rows: rows(for: sections.equity))
        html += table(for: "Balans: Passiva", rows: rows(for: sections.liabilities))
        if options.includeOtherBucket {
            html += table(for: "Balance Sheet — Other", rows: rows(for: sections.other))
        }

        // 4c) Summary check (Assets == Equity + Liabilities)
        if let sum = sections.summary {
            let ajk = sum.equity + sum.liabilities
            let ok  = (sum.assets == ajk)
            // html += """
            // <div class="summary">
            //   <strong>Check:</strong> Assets (\(fmt(sum.assets))) == Equity + Liabilities (\(fmt(ajk))) → \
            //   <span class="\(ok ? "ok" : "warn")">\(ok ? "OK" : "DIFF: " + fmt(sum.assets - ajk))</span>
            // </div>
            // """

            html += """
            <div class="summary">
                Som Activa: \(fmt(sum.assets))
            </div>

            <div class="summary">
                Som Eigen Vermogen, Passiva: \(fmt(sum.assets))
            </div>

            <div class="summary">
                <span class="\(ok ? "" : "warn")">\(ok ? "" : "DIFF: " + fmt(sum.assets - ajk))</span>
            </div>
            """
        }

        html += "</body></html>"
        return html
    }
}
