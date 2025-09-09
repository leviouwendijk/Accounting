import Foundation

public extension RGSAssembler {
    /// Build a BTW/VAT overview model for rendering (no console printing).
    static func vatOverview(
        _ title: String = "BTW / Taxes Overview",
        bundle: StatementBundle,
        chart: CompiledChart,
        includeCorrections: Bool = true,
        minAbs: Decimal = 0
    ) throws -> VATOverview {
        let maps  = try RGSAssembler.makeMaps(from: chart) // dir/parent/sort maps
        let nodes = chart.nodes

        // Fast lookups
        let idByCode: [String:Int]  = Dictionary(uniqueKeysWithValues: nodes.map { ($0.codes.code, $0.id) })
        let codeById: [Int:String]  = Dictionary(uniqueKeysWithValues: nodes.map { ($0.id, $0.codes.code) })
        let labelById: [Int:String] = Dictionary(uniqueKeysWithValues: nodes.map { ($0.id, $0.labels.short) })
        let levelById: [Int:Int]    = Dictionary(uniqueKeysWithValues: nodes.map { ($0.id, Int($0.level)) })
        let dirById                 = maps.directionById
        let totals                  = bundle.totalsById

        @inline(__always)
        func shownAmount(for id: Int) -> Decimal {
            let raw = totals[id] ?? 0
            let dir = dirById[id] ?? .debit
            return RGSAssembler.present(raw, direction: dir, mode: .apply)
        }

        @inline(__always)
        func makeRow(_ code: String) -> VATOverview.Row? {
            guard let id = idByCode[code] else { return nil }
            let amount = shownAmount(for: id)
            let absAmt = amount < 0 ? -amount : amount
            if minAbs > 0, absAmt < minAbs { return nil }

            let label = labelById[id] ?? codeById[id] ?? code
            let level = levelById[id] ?? 0
            return .init(id: id, level: level, label: label, code: code, amount: amount)
        }

        func rows(for codes: [String]) -> [VATOverview.Row] {
            codes.compactMap(makeRow)
        }

        // ====== 1) BTW / Taxes (balance) ======
        let vatAndTaxesBalance: [String] = [
            "BSchBep", "BSchBepBtw",
            "BSchBepBtwBeg","BSchBepBtwOla","BSchBepBtwOlv","BSchBepBtwOlt","BSchBepBtwOlo",
            "BSchBepBtwOop","BSchBepBtwOlw","BSchBepBtwOlb","BSchBepBtwOlu",
            "BSchBepBtwVoo","BSchBepBtwVvd","BSchBepBtwSva","BSchBepBtwSda",
            "BSchBepBtwAfo","BSchBepBtwNah","BSchBepBtwOvm",
            "BSchBepBla","BSchBepBlv","BSchBepBlo","BSchBepBop","BSchBepBlw","BSchBepBlb","BSchBepBlu",
            "BSchBepBoo",
            "BSchBepEob","BSchBepBaf"
        ]

        // ====== 2) Vorderingen (tax receivables) ======
        let receivables: [String] = ["BVorVbk","BVorVbkVbk","BVorVbkTvo","BVorVbkTvl","BVorVbkTtb"]

        // ====== 3) Corrections (P&L, yearly) ======
        let corrections: [String] = includeCorrections ? ["WBedTraBot", "WBedAutBop"] : []

        // Build sections
        var sections: [VATOverview.Section] = []
        let sec1 = VATOverview.Section(title: title, rows: rows(for: vatAndTaxesBalance))
        if !sec1.rows.isEmpty { sections.append(sec1) }

        let sec2 = VATOverview.Section(title: "Vorderingen uit hoofde van belastingen", rows: rows(for: receivables))
        if !sec2.rows.isEmpty { sections.append(sec2) }

        if !corrections.isEmpty {
            let sec3 = VATOverview.Section(title: "Correcties (privégebruik) — winst & verlies", rows: rows(for: corrections))
            if !sec3.rows.isEmpty { sections.append(sec3) }
        }

        // Summaries
        var summaries: [VATOverview.Summary] = []

        if let btwId = idByCode["BSchBepBtw"] {
            summaries.append(.init(label: "Saldo BTW op balans (te betalen)", code: "BSchBepBtw", amount: shownAmount(for: btwId)))
        }
        if let euId = idByCode["BSchBepEob"] {
            summaries.append(.init(label: "Te betalen EU OB", code: "BSchBepEob", amount: shownAmount(for: euId)))
        }

        // Net position hint: (Te betalen BTW) − (Te vorderen BTW)
        var net: Decimal? = nil
        if let btw = idByCode["BSchBepBtw"], let tvo = idByCode["BVorVbkTvo"] {
            net = shownAmount(for: btw) - shownAmount(for: tvo)
            summaries.append(.init(label: "Netto BTW-positie (te betalen − te vorderen)", code: nil, amount: net!))
        }

        return .init(title: title, sections: sections, summaries: summaries, netPosition: net)
    }
}
