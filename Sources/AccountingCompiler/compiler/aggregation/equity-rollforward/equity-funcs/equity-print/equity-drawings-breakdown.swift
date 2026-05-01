import Accounting
import Foundation

public func printDrawingsBreakdown(
    title: String,
    entities: EntityStore,
    cfg: EquityRollforwardConfig,
    report: EquityDrawingsBreakdownReport
) {
    let names = ownerNameMap(entities)
    let d = cfg.fractionDigits
    let owners = report.owners

    print("\n\(title)")
    print(String(repeating: "—", count: title.count))

    var hdr = pad("Post", 32)
    for oid in owners {
        hdr += " " + pad(names[Int?(oid)] ?? "owner#\(oid)", 14)
    }
    hdr += " " + pad("Totaal", 14)
    print(hdr)

    for row in report.rows {
        var line = pad(row.label, 32)

        for oid in owners {
            let value = row.amountsByOwner[oid] ?? 0
            line += " " + pad(
                fmtDec(roundD(value, digits: d), digits: d),
                14,
                .right
            )
        }

        line += " " + pad(
            fmtDec(roundD(row.total, digits: d), digits: d),
            14,
            .right
        )

        print(line)

        let ownersWithBranches = owners.filter {
            !(row.branchRowsByOwner[$0] ?? []).isEmpty
        }

        for oid in ownersWithBranches {
            let ownerName = names[Int?(oid)] ?? "owner#\(oid)"
            let direct = row.directAmountsByOwner[oid] ?? 0

            print(
                "    \(ownerName) direct: \(fmtDec(roundD(direct, digits: d), digits: d))"
            )

            for branch in row.branchRowsByOwner[oid] ?? [] {
                let detail = branch.detail.map { " • \($0)" } ?? ""
                print(
                    "      \(branch.label): \(fmtDec(roundD(branch.amount, digits: d), digits: d))\(detail)"
                )
            }
        }
    }

    var tot = pad("TOTAAL", 32)
    for oid in owners {
        tot += " " + pad(
            fmtDec(roundD(report.totalsByOwner[oid] ?? 0, digits: d), digits: d),
            14,
            .right
        )
    }
    tot += " " + pad(
        fmtDec(roundD(report.grandTotal, digits: d), digits: d),
        14,
        .right
    )

    print(String(repeating: "—", count: 32 + 1 + 14 * (owners.count + 1)))
    print(tot)

    let verdict = report.reconcilesWithOnttrek ? "OK" : "DIFF"
    print("Check: Σ(posts) per owner equals Onttrek column → \(verdict)")

    if !report.uncapturedAudit.isEmpty {
        print("\n[Audit] Drawings codes under BEivKapPro* not matched by any group (signed totals):")
        for k in report.uncapturedAudit.keys.sorted() {
            let v = report.uncapturedAudit[k] ?? 0
            print("  • \(k): \(fmtDec(roundD(v, digits: d), digits: d))")
        }
    }
}
