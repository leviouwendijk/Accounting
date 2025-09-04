import Foundation

public enum RGSPrinter {
    public static func printBalanceByL2Buckets(
        _ title: String,
        bundle: StatementBundle,
        chart: CompiledChart,
        equityCode: String = "BEiv",
        includeOtherBucket: Bool = false
    ) throws {
        let maps     = try RGSAssembler.makeMaps(from: chart)
        let nodeById = Dictionary(uniqueKeysWithValues: chart.nodes.map { ($0.id, $0) })

        // Use analytics when present; compute otherwise (same model used by assembler)
        let analytics: BundleAnalytics = try bundle.analytics ?? {
            let l2  = try RGSAssembler.makeL2Buckets(chart: chart, defaultEquityCode: equityCode)
            let tot = try RGSAssembler.presentedTotalsByL2(chart: chart, bundle: bundle, buckets: l2, omslag: .apply)
            return BundleAnalytics(l2Buckets: l2, l2Totals: tot)
        }()

        let buckets = analytics.l2Buckets

        // Buckets
        var assetsLines:      [RGSPresentationLine] = []
        var equityLines:      [RGSPresentationLine] = []
        var liabilitiesLines: [RGSPresentationLine] = []
        var other:            [RGSPresentationLine] = []

        let assetsAnchorSet      = Set(buckets.assets)
        let liabilitiesAnchorSet = Set(buckets.liabilities)
        let equityAnchor         = buckets.equity

        for r in bundle.balance {
            guard let a = l2AncestorId(of: r.id, parentById: maps.parentById, nodeById: nodeById) else {
                other.append(r); continue
            }
            if let eq = equityAnchor, a == eq { equityLines.append(r); continue }
            if assetsAnchorSet.contains(a)      { assetsLines.append(r); continue }
            if liabilitiesAnchorSet.contains(a) { liabilitiesLines.append(r); continue }
            other.append(r)
        }

        // Sort each bucket by SortingKey (order only)
        func byKey(_ a: RGSPresentationLine, _ b: RGSPresentationLine) -> Bool {
            RGSNodeSortingCode(key: sortKey(for: a.id, maps)) < RGSNodeSortingCode(key: sortKey(for: b.id, maps))
        }
        assetsLines.sort(by: byKey)
        equityLines.sort(by: byKey)
        liabilitiesLines.sort(by: byKey)
        other.sort(by: byKey)

        // Anchors for relative indentation
        let anchorAssets      = assetsAnchorSet.first
        let anchorEquity      = equityAnchor
        let anchorLiabilities = liabilitiesAnchorSet.first

        // Print
        print("\n\(title)")
        print(String(repeating: "—", count: title.count))

        if !assetsLines.isEmpty {
            print("• Assets")
            print(String(repeating: "—", count: "Assets".count))
            for r in assetsLines {
                let rel = relativeIndent(for: r.id, anchorId: anchorAssets, parentById: maps.parentById)
                let indent = String(repeating: "  ", count: rel)
                print("\(indent)• \(r.label)  \(r.amount)")
            }
            if let t = bundle.analytics?.l2Totals { print("  — Subtotal Assets: \(t.assets)") }
            print("")
        }

        if !equityLines.isEmpty {
            print("• Equity")
            print(String(repeating: "—", count: "Equity".count))
            for r in equityLines {
                let rel = relativeIndent(for: r.id, anchorId: anchorEquity, parentById: maps.parentById)
                let indent = String(repeating: "  ", count: rel)
                print("\(indent)• \(r.label)  \(r.amount)")
            }
            if let t = bundle.analytics?.l2Totals { print("  — Subtotal Equity: \(t.equity)") }
            print("")
        }

        if !liabilitiesLines.isEmpty {
            print("• Liabilities")
            print(String(repeating: "—", count: "Liabilities".count))
            for r in liabilitiesLines {
                let rel = relativeIndent(for: r.id, anchorId: anchorLiabilities, parentById: maps.parentById)
                let indent = String(repeating: "  ", count: rel)
                print("\(indent)• \(r.label)  \(r.amount)")
            }
            if let t = bundle.analytics?.l2Totals { print("  — Subtotal Liabilities: \(t.liabilities)") }
            print("")
        }

        if includeOtherBucket, !other.isEmpty {
            print("• Other")
            print(String(repeating: "—", count: "Other".count))
            for r in other {
                let rel = max(0, graphDepth(of: r.id, parentById: maps.parentById) - 1)
                let indent = String(repeating: "  ", count: rel)
                print("\(indent)• \(r.label)  \(r.amount)")
            }
            print("")
        }

        if let t = bundle.analytics?.l2Totals {
            print("== Summary ==")
            print("Subtotal Equity + Liabilities: \(t.equityPlusLiabilities)")
            print()
            print("Check: ( Assets ==  Equity + Liabilities )? → ( \(t.assets) == \(t.equityPlusLiabilities) )")
        }
    }
}
