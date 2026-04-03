import Foundation

public extension RGSPrinter {
    static func vatOverview(
        _ title: String = "BTW / Taxes Overview",
        bundle: StatementBundle,
        chart: CompiledChart,
        includeCorrections: Bool = true,
        minAbs: Decimal = 0
    ) throws {
        let overview = try RGSAssembler.vatOverview(
            title,
            bundle: bundle,
            chart: chart,
            includeCorrections: includeCorrections,
            minAbs: minAbs
        )

        let labelCol = 60
        let codeCol = 25
        let gapSpace = 2
        let gap = String(repeating: " ", count: gapSpace)
        let labelWidth = labelCol - gapSpace

        @inline(__always)
        func wrapLabel(
            _ text: String,
            indent: Int,
            width: Int
        ) -> [String] {
            let prefix = String(
                repeating: " ",
                count: indent
            )

            var words = text
                .split(
                    separator: " ",
                    omittingEmptySubsequences: false
                )
                .map(String.init)

            var lines: [String] = []
            var line = ""

            func flush() {
                lines.append(
                    prefix + line.trimmingCharacters(
                        in: .whitespaces
                    )
                )
                line = ""
            }

            while !words.isEmpty {
                let word = words.removeFirst()
                let candidate = line.isEmpty
                    ? word
                    : line + " " + word

                if prefix.count + candidate.count <= width {
                    line = candidate
                    continue
                }

                if !line.isEmpty {
                    flush()

                    if prefix.count + word.count <= width {
                        line = word
                    } else {
                        var index = word.startIndex
                        while index < word.endIndex {
                            let next = word.index(
                                index,
                                offsetBy: max(1, width - prefix.count),
                                limitedBy: word.endIndex
                            ) ?? word.endIndex

                            lines.append(
                                prefix + String(word[index..<next])
                            )

                            index = next
                        }
                    }

                    continue
                }

                var index = word.startIndex
                while index < word.endIndex {
                    let next = word.index(
                        index,
                        offsetBy: max(1, width - prefix.count),
                        limitedBy: word.endIndex
                    ) ?? word.endIndex

                    lines.append(
                        prefix + String(word[index..<next])
                    )

                    index = next
                }
            }

            if !line.isEmpty {
                flush()
            }

            if lines.isEmpty {
                lines = [prefix]
            }

            return lines
        }

        func printSection(
            _ section: VATOverview.Section
        ) {
            guard !section.rows.isEmpty else {
                return
            }

            printHeader(section.title)
            print(
                pad("Label", labelWidth)
                    + gap
                    + pad("Code", codeCol)
                    + "Amount"
            )

            let baseLevel = section.rows
                .map(\.level)
                .min() ?? 0

            for row in section.rows {
                let indentSpaces = max(
                    0,
                    (row.level - baseLevel) * 2
                )

                let wrapped = wrapLabel(
                    row.label,
                    indent: indentSpaces,
                    width: labelWidth
                )

                if let first = wrapped.first {
                    print(
                        pad(first, labelWidth)
                            + gap
                            + pad(row.code, codeCol)
                            + fmtDec(row.amount)
                    )
                }

                for continuation in wrapped.dropFirst() {
                    print(
                        pad(continuation, labelWidth)
                    )
                }
            }
        }

        var printedAnySection = false

        for section in overview.sections {
            if printedAnySection {
                print("")
            }

            printSection(section)
            printedAnySection = true
        }

        if !overview.summaries.isEmpty || overview.netPosition != nil {
            if printedAnySection {
                print("")
            }

            printHeader("Samenvatting")
            print(
                pad("Label", labelWidth)
                    + gap
                    + pad("Code", codeCol)
                    + "Amount"
            )

            for summary in overview.summaries {
                print(
                    pad(summary.label, labelWidth)
                        + gap
                        + pad(summary.code ?? "—", codeCol)
                        + fmtDec(summary.amount)
                )
            }

            if let netPosition = overview.netPosition {
                print(
                    pad(
                        "Netto BTW-positie (te betalen − te vorderen)",
                        labelWidth
                    )
                        + gap
                        + pad("—", codeCol)
                        + fmtDec(netPosition)
                )
            }
        }
    }
}

// public extension RGSPrinter {
//     static func vatOverview(
//         _ title: String = "BTW / Taxes Overview",
//         bundle: StatementBundle,
//         chart: CompiledChart,
//         includeCorrections: Bool = true,
//         minAbs: Decimal = 0
//     ) throws {
//         let maps = try RGSAssembler.makeMaps(from: chart) // dir/parent/sort maps
//         let nodes = chart.nodes

//         let idByCode: [String:Int]  = Dictionary(uniqueKeysWithValues: nodes.map { ($0.codes.code, $0.id) })
//         let codeById: [Int:String]  = Dictionary(uniqueKeysWithValues: nodes.map { ($0.id, $0.codes.code) })
//         let labelById: [Int:String] = Dictionary(uniqueKeysWithValues: nodes.map { ($0.id, $0.labels.short) })
//         let levelById: [Int:Int] = Dictionary(uniqueKeysWithValues: nodes.map { ($0.id, Int($0.level)) })
//         let dirById = maps.directionById
//         let totals  = bundle.totalsById

//         // Column widths (same footprint as your other printers)
//         let labelCol = 60
//         let codeCol  = 25
//         let gapSpace = 2
//         let gap = String(repeating: " ", count: gapSpace)
//         let labelWidth = labelCol - gapSpace

//         @inline(__always)
//         func shownAmount(for id: Int) -> Decimal {
//             let raw = totals[id] ?? 0
//             let dir = dirById[id] ?? .debit
//             return RGSAssembler.present(raw, direction: dir, mode: .apply)
//         }

//         @inline(__always)
//         func line(_ code: String) -> (id: Int, level: Int, label: String, code: String, amount: Decimal)? {
//             guard let id = idByCode[code] else { return nil }
//             let amt = shownAmount(for: id)
//             let absAmt = amt < 0 ? -amt : amt
//             if minAbs > 0, absAmt < minAbs { return nil }
//             let lbl = labelById[id] ?? codeById[id] ?? code
//             let lvl = levelById[id] ?? 0
//             return (id, lvl, lbl, code, amt)
//         }

//         // Soft word-wrap for the label column, with hard-wrap fallback for extra-long tokens.
//         @inline(__always)
//         func wrapLabel(_ text: String, indent: Int, width: Int) -> [String] {
//             let prefix = String(repeating: " ", count: indent)
//             var words = text.split(separator: " ", omittingEmptySubsequences: false).map(String.init)
//             var lines: [String] = []
//             var line = ""

//             func flush() {
//                 lines.append(prefix + line.trimmingCharacters(in: .whitespaces))
//                 line = ""
//             }

//             while !words.isEmpty {
//                 let w = words.removeFirst()
//                 let candidate = line.isEmpty ? w : (line + " " + w)
//                 if prefix.count + candidate.count <= width {
//                     line = candidate
//                 } else if !line.isEmpty {
//                     flush()
//                     if prefix.count + w.count <= width {
//                         line = w
//                     } else {
//                         // hard-wrap this long token
//                         var idx = w.startIndex
//                         while idx < w.endIndex {
//                             let next = w.index(idx, offsetBy: max(1, width - prefix.count), limitedBy: w.endIndex) ?? w.endIndex
//                             lines.append(prefix + String(w[idx..<next]))
//                             idx = next
//                         }
//                         line = ""
//                     }
//                 } else {
//                     // first word already too long → hard-wrap
//                     var idx = w.startIndex
//                     while idx < w.endIndex {
//                         let next = w.index(idx, offsetBy: max(1, width - prefix.count), limitedBy: w.endIndex) ?? w.endIndex
//                         lines.append(prefix + String(w[idx..<next]))
//                         idx = next
//                     }
//                     line = ""
//                 }
//             }
//             if !line.isEmpty { flush() }
//             if lines.isEmpty { lines = [prefix] }
//             return lines
//         }

//         @inline(__always)
//         func printTable(_ heading: String, codes: [String]) {
//             let rows = codes.compactMap(line)
//             guard !rows.isEmpty else { return }

//             printHeader("\n\(heading)")
//             // header with gap
//             print(pad("Label", labelWidth) + gap + pad("Code", codeCol) + "Amount")

//             // Align indent relative to the shallowest level in this table
//             let baseLevel = rows.map { $0.level }.min() ?? 3

//             for r in rows {
//                 let indentSpaces = max(0, (r.level - baseLevel) * 2)  // 2 spaces per level step
//                 // wrap to labelWidth (not labelCol)
//                 let wrapped = wrapLabel(r.label, indent: indentSpaces, width: labelWidth)

//                 // First physical line: full row with Code & Amount
//                 if let first = wrapped.first {
//                     print(pad(first, labelWidth) + gap + pad(r.code, codeCol) + fmtDec(r.amount))
//                 }

//                 // Continuation lines: label only (skip Code/Amount columns)
//                 for cont in wrapped.dropFirst() {
//                     print(pad(cont, labelWidth))
//                 }
//             }
//         }

//         // ====== 1) BTW / Taxes (balance) ======
//         let vatAndTaxesBalance: [String] = [
//             "BSchBep", "BSchBepBtw",
//             "BSchBepBtwBeg","BSchBepBtwOla","BSchBepBtwOlv","BSchBepBtwOlt","BSchBepBtwOlo",
//             "BSchBepBtwOop","BSchBepBtwOlw","BSchBepBtwOlb","BSchBepBtwOlu",
//             "BSchBepBtwVoo","BSchBepBtwVvd","BSchBepBtwSva","BSchBepBtwSda",
//             "BSchBepBtwAfo","BSchBepBtwNah","BSchBepBtwOvm",
//             "BSchBepBla","BSchBepBlv","BSchBepBlo","BSchBepBop","BSchBepBlw","BSchBepBlb","BSchBepBlu",
//             "BSchBepBoo",
//             "BSchBepEob","BSchBepBaf"
//         ]
//         printTable(title, codes: vatAndTaxesBalance)

//         // Summary (parents only to avoid double count)
//         if let btwId = idByCode["BSchBepBtw"] {
//             print(pad("Saldo BTW op balans (te betalen)", labelWidth) + gap
//                   + pad("BSchBepBtw", codeCol) + fmtDec(shownAmount(for: btwId)))
//         }
//         if let euId = idByCode["BSchBepEob"] {
//             print(pad("Te betalen EU OB", labelWidth) + gap
//                   + pad("BSchBepEob", codeCol) + fmtDec(shownAmount(for: euId)))
//         }

//         // ====== 2) Vorderingen (tax receivables) ======
//         let receivables: [String] = ["BVorVbk","BVorVbkVbk","BVorVbkTvo","BVorVbkTvl","BVorVbkTtb"]
//         printTable("\nVorderingen uit hoofde van belastingen", codes: receivables)

//         if let tvoId = idByCode["BVorVbkTvo"] {
//             print(pad("Te vorderen BTW", labelWidth) + gap
//                   + pad("BVorVbkTvo", codeCol) + fmtDec(shownAmount(for: tvoId)))
//         }

//         // Net position hint: (Te betalen BTW) − (Te vorderen BTW)
//         if let btw = idByCode["BSchBepBtw"], let tvo = idByCode["BVorVbkTvo"] {
//             let net = shownAmount(for: btw) - shownAmount(for: tvo)
//             print(pad("Netto BTW-positie (te betalen − te vorderen)", labelWidth) + gap
//                   + pad("—", codeCol) + fmtDec(net))
//         }

//         // ====== 3) Corrections (P&L, yearly) ======
//         if includeCorrections {
//             let corrections: [String] = ["WBedTraBot", "WBedAutBop"]
//             printTable("\nCorrecties (privégebruik) — winst & verlies", codes: corrections)
//         }
//     }
// }
