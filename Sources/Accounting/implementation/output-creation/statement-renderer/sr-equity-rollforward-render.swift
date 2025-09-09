import Foundation

public extension StatementHTMLRenderer {
    @inline(__always)
    static func escape(_ s: String) -> String {
        var out = String()
        out.reserveCapacity(s.count)
        for ch in s {
            switch ch {
            case "&": out += "&amp;"
            case "<": out += "&lt;"
            case ">": out += "&gt;"
            case "\"": out += "&quot;"
            case "'": out += "&#39;"
            default: out.append(ch)
            }
        }
        return out
    }

    static func renderEquityOverviewHTML(
        title: String,
        history: [EquityPeriod],           // full history from inception
        chart: CompiledChart,
        entities: EntityStore,
        view: ClosedRange<Int>? = nil,     // which periods to show
        options: Options = .init()         // re-use existing StatementHTMLRenderer.Options
    ) throws -> String {
        let cfg = EquityRollforwardConfig()

        // 1) Build the rollforward over the *entire* history (keeps math correct),
        // then slice to the requested window.
        let roll = try buildGlobalRollforward(history: history, chart: chart, entities: entities, cfg: cfg)
        guard !roll.isEmpty else {
            return """
            <html><head><meta charset="utf-8"><style>
              body{font-family:-apple-system,BlinkMacSystemFont,Helvetica,Arial,sans-serif;margin:24px}
              .sub{color:#666;margin-top:-8px;margin-bottom:16px}
              table{border-collapse:collapse;width:100%;margin:16px 0}
              th,td{border-bottom:1px solid #ddd;padding:6px 8px;text-align:right;white-space:nowrap}
              th.left,td.left{text-align:left}
              td.amount.neg{color:#b00}
              .period{margin-top:28px}
              .summary{margin:8px 0;color:#444}
            </style></head>
            <body>
              <h1>\(escape(title))</h1>
              \(options.subtitle.map { "<div class=\"sub\">\(escape($0))</div>" } ?? "")
              <p>Geen periodes.</p>
            </body></html>
            """
        }

        let lo0 = view?.lowerBound ?? 0
        let hi0 = view?.upperBound ?? (roll.count - 1)
        let lo = max(0, min(lo0, roll.count - 1))
        let hi = max(lo, min(hi0, roll.count - 1))
        let shown = Array(roll[lo...hi])
        let shownLabels = Array(history[lo...hi].map { $0.label })

        let names = ownerNameMap(entities) // id -> display name  :contentReference[oaicite:2]{index=2}
        @inline(__always) func fmt(_ x: Decimal) -> String {
            fmtDec(roundD(x, digits: cfg.fractionDigits), digits: cfg.fractionDigits) // :contentReference[oaicite:3]{index=3}
        }

        var html = """
        <html><head><meta charset="utf-8"><style>
          body{font-family:-apple-system,BlinkMacSystemFont,Helvetica,Arial,sans-serif;margin:24px}
          .sub{color:#666;margin-top:-8px;margin-bottom:16px}
          table{border-collapse:collapse;width:100%;margin:16px 0}
          th,td{border-bottom:1px solid #ddd;padding:6px 8px;text-align:right;white-space:nowrap}
          th.left,td.left{text-align:left}
          td.amount.neg{color:#b00}
          .period{margin-top:28px}
          .summary{margin:8px 0;color:#444}
        </style></head>
        <body>
          <h1>\(escape(title))</h1>
          \(options.subtitle.map { "<div class=\"sub\">\(escape($0))</div>" } ?? "")
        """

        for (idx, period) in shown.enumerated() {
            let label = shownLabels[idx]
            html += """
            <div class="period">
              <h2>\(escape(label))</h2>
              <div class="summary">Winst bron: \(escape(period.winstSource.description))</div>
              <div class="summary">• Nettowinst (totaal, geïnjecteerd): \(fmt(period.niTotal))</div>

              <table>
                <thead>
                  <tr>
                    <th class="left">Eigenaar</th>
                    <th>Beginvermogen</th>
                    <th>Stortingen</th>
                    <th>Onttrekkingen</th>
                    <th>Winstaandeel</th>
                    <th>Eindvermogen</th>
                  </tr>
                </thead>
                <tbody>
            """

            var tBegin: Decimal = 0, tStort: Decimal = 0, tOnt: Decimal = 0, tWinst: Decimal = 0, tEnd: Decimal = 0

            for oid in period.owners {
                let nm    = names[Int?(oid)] ?? "owner#\(oid)"
                let begin = period.beginByOwner[oid] ?? 0
                let dlt   = period.deltas[oid] ?? OwnerDelta(stort: 0, onttrek: 0, winst: 0)
                let end   = period.endByOwner[oid] ?? (begin + dlt.delta)

                tBegin += begin; tStort += dlt.stort; tOnt += dlt.onttrek; tWinst += dlt.winst; tEnd += end

                let clsEnd  = end   < 0 ? " class=\"amount neg\"" : " class=\"amount\""
                let clsBeg  = begin < 0 ? " class=\"amount neg\"" : " class=\"amount\""
                let clsSto  = dlt.stort   < 0 ? " class=\"amount neg\"" : " class=\"amount\""
                let clsOnt  = dlt.onttrek < 0 ? " class=\"amount neg\"" : " class=\"amount\""
                let clsWin  = dlt.winst   < 0 ? " class=\"amount neg\"" : " class=\"amount\""

                html += """
                  <tr>
                    <td class="left">\(escape(nm))</td>
                    <td\(clsBeg)>\(fmt(begin))</td>
                    <td\(clsSto)>\(fmt(dlt.stort))</td>
                    <td\(clsOnt)>\(fmt(dlt.onttrek))</td>
                    <td\(clsWin)>\(fmt(dlt.winst))</td>
                    <td\(clsEnd)>\(fmt(end))</td>
                  </tr>
                """
            }

            html += """
                </tbody>
                <tfoot>
                  <tr>
                    <th class="left">TOTAAL</th>
                    <th>\(fmt(tBegin))</th>
                    <th>\(fmt(tStort))</th>
                    <th>\(fmt(tOnt))</th>
                    <th>\(fmt(tWinst))</th>
                    <th>\(fmt(tEnd))</th>
                  </tr>
                </tfoot>
              </table>
              <div class="summary">Check totals → Opening: \(fmt(period.openingTotal)) | Closing: \(fmt(period.closingTotal))</div>
              <div class="summary">Identity: Begin + Stort − Onttrek + Winst = \(fmt(tEnd))</div>
            </div>
            """
        }

        html += "</body></html>"
        return html
    }
}
