import Foundation

public extension RGSPrinter {
    /// VAT / Taxes balance overview + optional corrections subview.
    /// Prints three tables:
    ///  1) BTW / Taxes (balance)  2) Vorderingen (tax receivables)  3) Corrections (P&L)
    static func vatOverview(
        _ title: String = "BTW / Taxes Overview",
        bundle: StatementBundle,
        chart: CompiledChart,
        includeCorrections: Bool = true,
        minAbs: Decimal = 0
    ) throws {
        // Maps + quick indices (same approach as other printers)
        let maps = try RGSAssembler.makeMaps(from: chart) // dir/parent/sort index maps
        let nodes = chart.nodes

        let idByCode: [String:Int]  = Dictionary(uniqueKeysWithValues: nodes.map { ($0.codes.code, $0.id) })
        let codeById: [Int:String]  = Dictionary(uniqueKeysWithValues: nodes.map { ($0.id, $0.codes.code) })
        let labelById: [Int:String] = Dictionary(uniqueKeysWithValues: nodes.map { ($0.id, $0.labels.short) })
        let dirById = maps.directionById
        let totals  = bundle.totalsById

        @inline(__always)
        func shownAmount(for id: Int) -> Decimal {
            let raw = totals[id] ?? 0
            let dir = dirById[id]!
            // Present just like your other printers (flip by natural direction)
            return RGSAssembler.present(raw, direction: dir, mode: .apply)
        }

        @inline(__always)
        func line(_ code: String) -> (label: String, code: String, amount: Decimal)? {
            guard let id = idByCode[code] else { return nil }
            let amt = shownAmount(for: id)
            let absAmt = (amt < 0 ? -amt : amt)
            if minAbs > 0, absAmt < minAbs { return nil }
            let lbl = labelById[id] ?? codeById[id] ?? code
            return (lbl, code, amt)
        }

        @inline(__always)
        func printTable(_ heading: String, codes: [String]) {
            let lines = codes.compactMap(line)
            guard !lines.isEmpty else { return }

            printHeader("\n\(heading)")
            print(pad("Label", 56) + pad("Code", 13) + "Amount")

            for r in lines {
                print(pad(r.label, 56) + pad(r.code, 13) + fmtDec(r.amount))
            }
        }

        // ====== 1) BTW / Taxes (balance) ======
        // Keep your explicit codes; we list L5 details AND some L4 anchors as an overview.
        // (We don't sum anchors with children to avoid double counting in subtotals.)
        let vatAndTaxesBalance: [String] = [
            // Overkoepelend + BTW-blok (Te betalen Omzetbelasting)
            "BSchBep", "BSchBepBtw",
            "BSchBepBtwBeg","BSchBepBtwOla","BSchBepBtwOlv","BSchBepBtwOlt","BSchBepBtwOlo",
            "BSchBepBtwOop","BSchBepBtwOlw","BSchBepBtwOlb","BSchBepBtwOlu",
            "BSchBepBtwVoo","BSchBepBtwVvd","BSchBepBtwSva","BSchBepBtwSda",
            "BSchBepBtwAfo","BSchBepBtwNah","BSchBepBtwOvm",
            // L4 mirrors (reporting variants)
            "BSchBepBla","BSchBepBlv","BSchBepBlo","BSchBepBop","BSchBepBlw","BSchBepBlb","BSchBepBlu",
            "BSchBepBoo",
            // EU OB + Afdracht
            "BSchBepEob","BSchBepBaf"
        ]
        printTable(title, codes: vatAndTaxesBalance)

        // Summary lines (use the parent IDs directly — avoids child double count)
        if let btwId = idByCode["BSchBepBtw"] {
            let saldoBtw = shownAmount(for: btwId)
            print(pad("Saldo BTW op balans (te betalen)", 56) + pad("BSchBepBtw", 13) + fmtDec(saldoBtw))
        }
        if let euId = idByCode["BSchBepEob"] {
            let saldoEU = shownAmount(for: euId)
            print(pad("Te betalen EU OB", 56) + pad("BSchBepEob", 13) + fmtDec(saldoEU))
        }

        // ====== 2) Vorderingen (tax receivables) ======
        let receivables: [String] = [
            "BVorVbk","BVorVbkVbk",
            "BVorVbkTvo","BVorVbkTvl","BVorVbkTtb"
        ]
        printTable("\nVorderingen uit hoofde van belastingen", codes: receivables)

        if let tvoId = idByCode["BVorVbkTvo"] {
            let tevorderen = shownAmount(for: tvoId)
            print(pad("Te vorderen BTW", 56) + pad("BVorVbkTvo", 13) + fmtDec(tevorderen))
        }

        // Optional net position hint: (Te betalen BTW) − (Te vorderen BTW)
        if let btw = idByCode["BSchBepBtw"], let tvo = idByCode["BVorVbkTvo"] {
            let net = shownAmount(for: btw) - shownAmount(for: tvo)
            print(pad("Netto BTW-positie (te betalen − te vorderen)", 56) + pad("—", 13) + fmtDec(net))
        }

        // ====== 3) Corrections (P&L, yearly) ======
        if includeCorrections {
            let corrections: [String] = [
                "WBedTraBot", // BTW op privé-gebruik transportmiddelen
                "WBedAutBop"  // BTW op privé-gebruik auto's en andere vervoermiddelen
            ]
            printTable("\nCorrecties (privégebruik) — winst & verlies", codes: corrections)
        }
    }
}
