import Foundation

public func printDrawingsBreakdown(
    title: String,
    owners: [Int],
    deltas: [Int: OwnerDelta],
    entities: EntityStore,
    cfg: EquityRollforwardConfig,
    breakdown: DrawingsBreakdown
) {
    let names = ownerNameMap(entities)   // id -> display name
    let d = cfg.fractionDigits

    print("\n\(title)")
    print(String(repeating: "—", count: title.count))

    // Header
    var hdr = pad("Post", 32)
    for oid in owners { hdr += " " + pad(names[Int?(oid)] ?? "owner#\(oid)", 14) }
    hdr += " " + pad("Totaal", 14)
    print(hdr)

    // Body
    var perOwnerSum: [Int: Decimal] = [:]
    var grandTotal: Decimal = 0
    for (label, perOwner) in breakdown.perGroupPerOwner {
        var row = pad(label, 32)
        var rowTotal: Decimal = 0
        for oid in owners {
            let v = perOwner[oid] ?? 0
            perOwnerSum[oid, default: 0] += v
            rowTotal += v
            row += " " + pad(fmtDec(roundD(v, digits: d), digits: d), 14, .right)
        }
        grandTotal += rowTotal
        row += " " + pad(fmtDec(roundD(rowTotal, digits: d), digits: d), 14, .right)
        print(row)
    }

    var tot = pad("TOTAAL", 32)
    for oid in owners {
        tot += " " + pad(fmtDec(roundD(perOwnerSum[oid] ?? 0, digits: d), digits: d), 14, .right)
    }
    tot += " " + pad(fmtDec(roundD(grandTotal, digits: d), digits: d), 14, .right)
    print(String(repeating: "—", count: 32 + 1 + 14*(owners.count + 1)))
    print(tot)

    // Identity check vs Onttrek column already printed in the rollforward
    var ok = true
    for oid in owners {
        let onttrek = deltas[oid]?.onttrek ?? 0
        let det     = perOwnerSum[oid] ?? 0
        if roundD(onttrek - det, digits: d) != 0 { ok = false; break }
    }
    let verdict = ok ? "OK" : "DIFF"
    print("Check: Σ(posts) per owner equals Onttrek column → \(verdict)")

    // Optional: leak uncaptured for debugging if any
    if !breakdown.uncapturedAudit.isEmpty {
        print("\n[Audit] Drawings codes under BEivKapPro* not matched by any group (signed totals):")
        for k in breakdown.uncapturedAudit.keys.sorted() {
            let v = breakdown.uncapturedAudit[k] ?? 0
            print("  • \(k): \(fmtDec(roundD(v, digits: d), digits: d))")
        }
    }
}
