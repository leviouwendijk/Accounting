import Foundation

public extension StatementHTMLRenderer {
    /// Convenience: build + render from periods.
    static func renderEquityOverviewHTML(
        title: String = "Eigen Vermogen – Overzicht (per eigenaar)",
        allPeriods: [EquityPeriod],
        chart: CompiledChart,
        entities: EntityStore,
        view: ClosedRange<Int>? = nil,
        options: Options = .init(title: "Eigen Vermogen – Overzicht"),
        config: EquityRollforwardConfig = .init()
    ) throws -> String {
        let periods = try RGSPrinter.buildOwnerEquityRollforwardHistoryData(
            allPeriods: allPeriods,
            chart: chart,
            entities: entities,
            view: view,
            config: config
        )
        return renderEquityOverviewHTML(
            title: title,
            periods: periods,
            periodLabels: allPeriods.map(\.label),
            entities: entities,
            options: options
        )
    }

    /// Core: render an already-built rollforward history.
    static func renderEquityOverviewHTML(
        title: String,
        periods: [PeriodRollforward],
        periodLabels: [String],
        entities: EntityStore,
        options: Options = .init(title: "Eigen Vermogen – Overzicht")
    ) -> String {
        // Owner id → display name
        let idx = entities.idIndex
        var idToName: [Int: String] = [:]
        for (key, id) in idx {
            idToName[id] = entities.byFull[key]?.displayName
                ?? key.identifier(displaying: .fullchain)
        }

        func fmtCurrency(_ x: Decimal) -> String {
            let nf = NumberFormatter()
            nf.locale = Locale(identifier: "nl_NL")
            nf.numberStyle = .currency
            nf.currencySymbol = options.currencySymbol
            nf.minimumFractionDigits = 2
            nf.maximumFractionDigits = 2
            return nf.string(from: x as NSDecimalNumber) ?? x.description
        }
        func fmtPercent(_ x: Decimal) -> String {
            let nf = NumberFormatter()
            nf.locale = Locale(identifier: "nl_NL")
            nf.numberStyle = .percent
            nf.minimumFractionDigits = 0
            nf.maximumFractionDigits = 2
            return nf.string(from: x as NSDecimalNumber) ?? "\(x * 100)%"
        }

        var html: [String] = []
        html.append("""
        <!doctype html>
        <html lang="nl">
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <title>\(title)</title>
          <style>
            :root {
              --pad: 48px;
              --row-pad: 10px 12px;
              --border: #eee;
              --muted: #666;
              --neg: #b00020;
            }
            body { font-family: -apple-system,BlinkMacSystemFont,Segoe UI,Roboto,Helvetica,Arial,sans-serif; margin: var(--pad); }
            h1 { font-size: 24px; margin: 0 0 8px; }
            h2 { font-size: 18px; margin: 24px 0 8px; }
            .sub { color: var(--muted); margin: 0 0 24px; }
            table { width: 100%; border-collapse: collapse; margin: 8px 0 16px; }
            th, td { padding: var(--row-pad); border-bottom: 1px solid var(--border); }
            th { text-align: right; font-weight: 600; }
            th:first-child, td:first-child { text-align: left; }
            td.amount { text-align: right; white-space: nowrap; }
            .neg { color: var(--neg); }
            .note { color: var(--muted); font-size: 12px; margin: 6px 0 0; }
          </style>
        </head>
        <body>
          <h1>\(title)</h1>
          \(options.subtitle.map { "<div class='sub'>\($0)</div>" } ?? "")
        """)

        for (i, p) in periods.enumerated() {
            // Period label (fallback if not provided)
            let heading = (i < periodLabels.count) ? periodLabels[i] : "Periode \(i+1)"
            html.append("<h2>\(heading)</h2>")

            // Column headers: owners + total
            var owners = p.owners
            owners.sort()
            let ownerNames = owners.map { idToName[$0] ?? "#\($0)" }

            html.append("<table><thead><tr>")
            html.append("<th>Post</th>")
            for n in ownerNames { html.append("<th>\(n)</th>") }
            html.append("<th>Totaal</th>")
            html.append("</tr></thead><tbody>")

            // Row helper
            @inline(__always)
            func line(_ label: String, _ perOwner: (Int) -> Decimal) {
                var total: Decimal = 0
                html.append("<tr>")
                html.append("<td>\(label)</td>")
                for oid in owners {
                    let v = perOwner(oid)
                    total += v
                    let cls = v < 0 ? " class='amount neg'" : " class='amount'"
                    html.append("<td\(cls)>\(fmtCurrency(v))</td>")
                }
                let tcls = total < 0 ? " class='amount neg'" : " class='amount'"
                html.append("<td\(tcls)>\(fmtCurrency(total))</td>")
                html.append("</tr>")
            }

            // BEGIN
            line("Beginvermogen", { p.beginByOwner[$0] ?? 0 })

            // Movements
            line("Stortingen",    { p.deltas[$0]?.stort   ?? 0 })
            line("Onttrekkingen", { p.deltas[$0]?.onttrek ?? 0 })
            line("Winstaandeel",  { p.deltas[$0]?.winst   ?? 0 })

            // END
            line("Eindvermogen",  { p.endByOwner[$0] ?? 0 })

            html.append("</tbody></table>")

            // Allocation note / metadata (same info as console)
            var notes: [String] = []
            switch p.winstSource {
            case .postedAOW:
                notes.append("Winstverdeling: geposteerd (AOW).")
            case .slices(let d):
                let df = DateFormatter()
                df.locale = Locale(identifier: "nl_NL")
                df.dateFormat = "yyyy-MM-dd"
                notes.append("Winstverdeling: eigenaarspercentages op \(df.string(from: d)).")
            }

            if !p.allocationNote.isEmpty {
                let parts = owners.map { oid -> String in
                    let (pct, amt) = (p.allocationNote[oid]?.percent ?? 0, p.allocationNote[oid]?.amount ?? 0)
                    return "\(idToName[oid] ?? "#\(oid)") \(fmtPercent(pct)) · \(fmtCurrency(amt))"
                }
                notes.append("Allocatie: " + parts.joined(separator: " · "))
            }

            // Optional opening/closing totals, if you want them visible:
            // notes.append("Opening totaal: \(fmtCurrency(p.openingTotal)) · Sluiting totaal: \(fmtCurrency(p.closingTotal))")

            if !notes.isEmpty {
                html.append("<div class='note'>\(notes.joined(separator: "<br>"))</div>")
            }
        }

        html.append("""
          </body>
        </html>
        """)
        return html.joined()
    }
}
