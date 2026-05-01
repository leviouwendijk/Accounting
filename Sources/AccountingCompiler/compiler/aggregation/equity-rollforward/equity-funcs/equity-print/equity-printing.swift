import Accounting
import Foundation

public func printHeader(
    _ title: String
) {
    print("\n\(title)")
    print(String(repeating: "—", count: title.count))
}

public func printPeriod(
    label: String,
    rows: PeriodRollforward,
    entities: EntityStore,
    cfg: EquityRollforwardConfig
) {
    let d = cfg.fractionDigits
    let ownerWidth = 34

    let table: EquityOwnerDisplayTable

    do {
        table = try makeEquityOwnerDisplayTable(
            rows: rows,
            entities: entities,
            cfg: cfg
        )
    } catch {
        print("\n\(label)")
        print("error: \(error)")
        return
    }

    func printableRowLabel(
        _ row: EquityOwnerDisplayRow
    ) -> String {
        let baseLabel: String

        if row.label.hasPrefix("  ") {
            baseLabel = "↳ " + String(row.label.dropFirst(2))
        } else {
            baseLabel = row.label
        }

        let exclusionSuffix = row.includeInSum
            ? ""
            : " [excluded]"

        if row.style == .subtotal {
            return "[subtotal] \(baseLabel)\(exclusionSuffix)"
        }

        return "\(baseLabel)\(exclusionSuffix)"
    }

    func printTableHeader() {
        print(
            "\(pad("Owner", ownerWidth)) " +
            "\(pad("Begin", 14, .right)) " +
            "\(pad("Stort", 14, .right)) " +
            "\(pad("Onttrek", 14, .right)) " +
            "\(pad("Winst", 14, .right)) " +
            "\(pad("Eind", 14, .right))"
        )
    }

    func printDisplayRow(
        _ row: EquityOwnerDisplayRow,
        digits d: Int
    ) {
        let name = printableRowLabel(row)

        print(
            "\(pad(name, ownerWidth)) " +
            "\(pad(fmtDec(row.begin, digits: d), 14, .right)) " +
            "\(pad(fmtDec(row.stort, digits: d), 14, .right)) " +
            "\(pad(fmtDec(row.onttrek, digits: d), 14, .right)) " +
            "\(pad(fmtDec(row.winst, digits: d), 14, .right)) " +
            "\(pad(fmtDec(row.end, digits: d), 14, .right))"
        )

        let detailLine = [
            row.detail,
            row.includeInSum ? nil : "Excluded from section total"
        ]
        .compactMap { value -> String? in
            guard let value, !value.isEmpty else {
                return nil
            }

            return value
        }
        .joined(separator: " • ")

        if !detailLine.isEmpty {
            print("    \(detailLine)")
        }
    }

    func printSectionFooter(
        _ section: EquityOwnerDisplaySectionTable
    ) {
        print(String(repeating: "-", count: ownerWidth + 1 + 14 * 5))
        print(
            "\(pad("TOTAAL", ownerWidth)) " +
            "\(pad(fmtDec(section.totalBegin, digits: d), 14, .right)) " +
            "\(pad(fmtDec(section.totalStort, digits: d), 14, .right)) " +
            "\(pad(fmtDec(section.totalOnttrek, digits: d), 14, .right)) " +
            "\(pad(fmtDec(section.totalWinst, digits: d), 14, .right)) " +
            "\(pad(fmtDec(section.totalEnd, digits: d), 14, .right))"
        )
    }

    print("\n\(label)")
    print("Winst source: \(rows.winstSource)")
    print("• Net income (total, injected): \(fmtDec(rows.niTotal, digits: d))")

    for (sectionIndex, section) in table.sections.enumerated() {
        if sectionIndex > 0 {
            print("")
        }

        printTableHeader()

        for row in section.rows {
            printDisplayRow(
                row,
                digits: d
            )
        }

        printSectionFooter(section)
    }

    let identity = table.actualTotalBegin
        + table.actualTotalStort
        - table.actualTotalOnttrek
        + table.actualTotalWinst

    print("")
    print(
        "Werkelijk totaal (ruw) → " +
        "Begin: \(fmtDec(table.actualTotalBegin, digits: d)) | " +
        "Stort: \(fmtDec(table.actualTotalStort, digits: d)) | " +
        "Onttrek: \(fmtDec(table.actualTotalOnttrek, digits: d)) | " +
        "Winst: \(fmtDec(table.actualTotalWinst, digits: d)) | " +
        "Eind: \(fmtDec(table.actualTotalEnd, digits: d))"
    )

    print(
        "Check totals → Opening: \(fmtDec(rows.openingTotal, digits: d)) | " +
        "Closing: \(fmtDec(rows.closingTotal, digits: d))"
    )

    print(
        "Identity: Begin + Stort − Onttrekkingen + Winst = " +
        "\(fmtDec(identity, digits: d))"
    )
}

// public func printHeader(_ title: String) {
//     print("\n\(title)")
//     print(String(repeating: "—", count: title.count))
// }

// public func printPeriod(label: String, rows: PeriodRollforward, entities: EntityStore, cfg: EquityRollforwardConfig) {
//     let names = ownerNameMap(entities)
//     let d = cfg.fractionDigits

//     print("\n\(label)")
//     print("Winst source: \(rows.winstSource)")
//     print("• Net income (total, injected): \(fmtDec(roundD(rows.niTotal, digits: d), digits: d))")
//     print("\(pad("Owner", 28)) \(pad("Begin", 14, .right)) \(pad("Stort", 14, .right)) \(pad("Onttrek", 14, .right)) \(pad("Winst", 14, .right)) \(pad("Eind", 14, .right))")

//     var tBegin = Decimal(0), tStort = Decimal(0), tOnt = Decimal(0), tWinst = Decimal(0), tEnd = Decimal(0)

//     for oid in rows.owners {
//         let nm = names[Int?(oid)] ?? "owner#\(oid)"
//         let b  = rows.beginByOwner[oid] ?? 0
//         let dlt = rows.deltas[oid] ?? OwnerDelta(stort: 0, onttrek: 0, winst: 0)
//         let e  = rows.endByOwner[oid] ?? (b + dlt.delta)

//         tBegin += b; tStort += dlt.stort; tOnt += dlt.onttrek; tWinst += dlt.winst; tEnd += e

//         print("\(pad(nm, 28)) " +
//               "\(pad(fmtDec(roundD(b, digits: d), digits: d), 14, .right)) " +
//               "\(pad(fmtDec(roundD(dlt.stort, digits: d), digits: d), 14, .right)) " +
//               "\(pad(fmtDec(roundD(dlt.onttrek, digits: d), digits: d), 14, .right)) " +
//               "\(pad(fmtDec(roundD(dlt.winst, digits: d), digits: d), 14, .right)) " +
//               "\(pad(fmtDec(roundD(e, digits: d), digits: d), 14, .right))")
//     }

//     print(String(repeating: "—", count: 28 + 1 + 14*5))
//     print("\(pad("TOTAL", 28)) " +
//           "\(pad(fmtDec(roundD(tBegin, digits: d), digits: d), 14, .right)) " +
//           "\(pad(fmtDec(roundD(tStort, digits: d), digits: d), 14, .right)) " +
//           "\(pad(fmtDec(roundD(tOnt,  digits: d), digits: d), 14, .right)) " +
//           "\(pad(fmtDec(roundD(tWinst,digits: d), digits: d), 14, .right)) " +
//           "\(pad(fmtDec(roundD(tEnd,  digits: d), digits: d), 14, .right))")

//     print("Check totals → Opening: \(fmtDec(roundD(rows.openingTotal, digits: d), digits: d)) | Closing: \(fmtDec(roundD(rows.closingTotal, digits: d), digits: d))")
//     print("Identity check: Begin + Stort − Onttrek + Winst = \(fmtDec(roundD(tBegin + tStort - tOnt + tWinst, digits: d), digits: d))")

//     if !rows.allocationNote.isEmpty {
//         print("NI allocation (used): \(rows.winstSource)")
//         for oid in rows.owners {
//             let nm = names[Int?(oid)] ?? "owner#\(oid)"
//             if let (p, amt) = rows.allocationNote[oid] {
//                 print("  • \(nm): \(fmtPct(p, digits: d))  →  \(fmtDec(roundD(amt, digits: d), digits: d))")
//             }
//         }
//     }
// }
