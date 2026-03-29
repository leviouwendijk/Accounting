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

    print("\n\(label)")
    print("Winst source: \(rows.winstSource)")
    print("• Net income (total, injected): \(fmtDec(roundD(rows.niTotal, digits: d), digits: d))")
    print(
        "\(pad("Owner", 28)) " +
        "\(pad("Begin", 14, .right)) " +
        "\(pad("Stort", 14, .right)) " +
        "\(pad("Onttrek", 14, .right)) " +
        "\(pad("Winst", 14, .right)) " +
        "\(pad("Eind", 14, .right))"
    )

    for (idx, row) in table.rows.enumerated() {
        if idx > 0 && row.startsNewSection {
            print("")
        }

        let name = row.style == .subtotal
            ? "[subtotal] \(row.label)"
            : row.label

        print(
            "\(pad(name, 28)) " +
            "\(pad(fmtDec(roundD(row.begin, digits: d), digits: d), 14, .right)) " +
            "\(pad(fmtDec(roundD(row.stort, digits: d), digits: d), 14, .right)) " +
            "\(pad(fmtDec(roundD(row.onttrek, digits: d), digits: d), 14, .right)) " +
            "\(pad(fmtDec(roundD(row.winst, digits: d), digits: d), 14, .right)) " +
            "\(pad(fmtDec(roundD(row.end, digits: d), digits: d), 14, .right))"
        )

        if let detail = row.detail, !detail.isEmpty {
            print("    \(detail)")
        }
    }

    print(String(repeating: "-", count: 103))
    print(
        "\(pad("TOTAAL", 28)) " +
        "\(pad(fmtDec(roundD(table.actualTotalBegin, digits: d), digits: d), 14, .right)) " +
        "\(pad(fmtDec(roundD(table.actualTotalStort, digits: d), digits: d), 14, .right)) " +
        "\(pad(fmtDec(roundD(table.actualTotalOnttrek, digits: d), digits: d), 14, .right)) " +
        "\(pad(fmtDec(roundD(table.actualTotalWinst, digits: d), digits: d), 14, .right)) " +
        "\(pad(fmtDec(roundD(table.actualTotalEnd, digits: d), digits: d), 14, .right))"
    )

    let identity = table.actualTotalBegin
        + table.actualTotalStort
        - table.actualTotalOnttrek
        + table.actualTotalWinst

    print("Check totals → Opening: \(fmtDec(roundD(rows.openingTotal, digits: d), digits: d)) | Closing: \(fmtDec(roundD(rows.closingTotal, digits: d), digits: d))")
    print("Identity: Begin + Stort − Onttrekkingen + Winst = \(fmtDec(roundD(identity, digits: d), digits: d))")
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
