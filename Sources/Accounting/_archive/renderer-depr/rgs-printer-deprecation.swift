// import Foundation

// extension RGSPrinter {
    // public static func printBalanceByL2Buckets(
    //     _ title: String,
    //     bundle: StatementBundle,
    //     chart: CompiledChart,
    //     equityCode: String = "BEiv",
    //     includeOtherBucket: Bool = false
    // ) throws {
    //     let maps     = try RGSAssembler.makeMaps(from: chart)
    //     let nodeById = Dictionary(uniqueKeysWithValues: chart.nodes.map { ($0.id, $0) })

    //     // Use analytics when present; compute otherwise (same model used by assembler)
    //     let analytics: BundleAnalytics = try bundle.analytics ?? {
    //         let l2  = try RGSAssembler.makeL2Buckets(chart: chart, defaultEquityCode: equityCode)
    //         let tot = try RGSAssembler.presentedTotalsByL2(chart: chart, bundle: bundle, buckets: l2, omslag: .apply)
    //         return BundleAnalytics(l2Buckets: l2, l2Totals: tot)
    //     }()

    //     let buckets = analytics.l2Buckets

    //     // Buckets
    //     var assetsLines:      [RGSPresentationLine] = []
    //     var equityLines:      [RGSPresentationLine] = []
    //     var liabilitiesLines: [RGSPresentationLine] = []
    //     var other:            [RGSPresentationLine] = []

    //     let assetsAnchorSet      = Set(buckets.assets)
    //     let liabilitiesAnchorSet = Set(buckets.liabilities)
    //     let equityAnchor         = buckets.equity

    //     for r in bundle.balance {
    //         guard let a = l2AncestorId(of: r.id, parentById: maps.parentById, nodeById: nodeById) else {
    //             other.append(r); continue
    //         }
    //         if let eq = equityAnchor, a == eq { equityLines.append(r); continue }
    //         if assetsAnchorSet.contains(a)      { assetsLines.append(r); continue }
    //         if liabilitiesAnchorSet.contains(a) { liabilitiesLines.append(r); continue }
    //         other.append(r)
    //     }

    //     // Sort each bucket by SortingKey (order only)
    //     func byKey(_ a: RGSPresentationLine, _ b: RGSPresentationLine) -> Bool {
    //         RGSNodeSortingCode(key: sortKey(for: a.id, maps)) < RGSNodeSortingCode(key: sortKey(for: b.id, maps))
    //     }
    //     assetsLines.sort(by: byKey)
    //     equityLines.sort(by: byKey)
    //     liabilitiesLines.sort(by: byKey)
    //     other.sort(by: byKey)

    //     // Anchors for relative indentation
    //     let anchorAssets      = assetsAnchorSet.first
    //     let anchorEquity      = equityAnchor
    //     let anchorLiabilities = liabilitiesAnchorSet.first

    //     // Print
    //     print("\n\(title)")
    //     print(String(repeating: "—", count: title.count))

    //     if !assetsLines.isEmpty {
    //         print("• Assets")
    //         print(String(repeating: "—", count: "Assets".count))
    //         for r in assetsLines {
    //             let rel = relativeIndent(for: r.id, anchorId: anchorAssets, parentById: maps.parentById)
    //             let indent = String(repeating: "  ", count: rel)
    //             print("\(indent)• \(r.label)  \(r.amount)")
    //         }
    //         if let t = bundle.analytics?.l2Totals { print("  — Subtotal Assets: \(t.assets)") }
    //         print("")
    //     }

    //     if !equityLines.isEmpty {
    //         print("• Equity")
    //         print(String(repeating: "—", count: "Equity".count))
    //         for r in equityLines {
    //             let rel = relativeIndent(for: r.id, anchorId: anchorEquity, parentById: maps.parentById)
    //             let indent = String(repeating: "  ", count: rel)
    //             print("\(indent)• \(r.label)  \(r.amount)")
    //         }
    //         if let t = bundle.analytics?.l2Totals { print("  — Subtotal Equity: \(t.equity)") }
    //         print("")
    //     }

    //     if !liabilitiesLines.isEmpty {
    //         print("• Liabilities")
    //         print(String(repeating: "—", count: "Liabilities".count))
    //         for r in liabilitiesLines {
    //             let rel = relativeIndent(for: r.id, anchorId: anchorLiabilities, parentById: maps.parentById)
    //             let indent = String(repeating: "  ", count: rel)
    //             print("\(indent)• \(r.label)  \(r.amount)")
    //         }
    //         if let t = bundle.analytics?.l2Totals { print("  — Subtotal Liabilities: \(t.liabilities)") }
    //         print("")
    //     }

    //     if includeOtherBucket, !other.isEmpty {
    //         print("• Other")
    //         print(String(repeating: "—", count: "Other".count))
    //         for r in other {
    //             let rel = max(0, graphDepth(of: r.id, parentById: maps.parentById) - 1)
    //             let indent = String(repeating: "  ", count: rel)
    //             print("\(indent)• \(r.label)  \(r.amount)")
    //         }
    //         print("")
    //     }

    //     if let t = bundle.analytics?.l2Totals {
    //         print("== Summary ==")
    //         print("Subtotal Equity + Liabilities: \(t.equityPlusLiabilities)")
    //         print()
    //         print("Check: ( Assets ==  Equity + Liabilities )? → ( \(t.assets) == \(t.equityPlusLiabilities) )")
    //     }
    // }

    // public static func printBalanceByL2Buckets(
    //     _ title: String,
    //     bundle: StatementBundle,
    //     chart: CompiledChart,
    //     equityCode: String,
    //     includeOtherBucket: Bool,
    //     showEntityBreakdown: Bool,
    //     entities: EntityStore,
    //     minAbs: Decimal = 0
    // ) throws {
    //     // call the existing printer first
    //     try RGSPrinter.printBalanceByL2Buckets(
    //         title,
    //         bundle: bundle,
    //         chart: chart,
    //         equityCode: equityCode,
    //         includeOtherBucket: includeOtherBucket
    //     )

    //     guard showEntityBreakdown, let eb = bundle.entity?.byAccount else { return }

    //     // id map is a PROPERTY, not a function
    //     let idx = entities.idIndex

    //     // entity id -> display name
    //     var idToName: [Int?: String] = [nil: "(unassigned)"]
    //     for (key, id) in idx {
    //         // avoid .fullchain inference; use alias string or configured displayName
    //         let name = entities.byFull[key]?.displayName ?? key.alias.string
    //         idToName[id] = name
    //     }

    //     // quick maps for codes
    //     let codeById: [Int:String] = Dictionary(uniqueKeysWithValues: chart.nodes.map { ($0.id, $0.codes.code) })

    //     print("\nEntity breakdown (inline)")
    //     print("———————————————————————")

    //     // iterate the already-presented balance lines (same order)
    //     for line in bundle.balance {
    //         let accId = line.id
    //         guard let byEnt = eb[accId], !byEnt.isEmpty else { continue }

    //         let total = byEnt.values.reduce(Decimal(0), +)
    //         // avoid Decimal.magnitude ambiguity
    //         let absTotal = (total < 0 ? -total : total)
    //         if minAbs > 0, absTotal < minAbs { continue }

    //         // reconstruct label for clarity
    //         let label = line.label
    //         let code  = codeById[accId] ?? ""
    //         print("• \(label) [\(code)]  \(total)")

    //         for (eid, amt) in byEnt.sorted(by: { ($0.key ?? 0) < ($1.key ?? 0) }) where amt != 0 {
    //             let absAmt = (amt < 0 ? -amt : amt)
    //             if minAbs > 0, absAmt < minAbs { continue }
    //             let nm = idToName[eid] ?? "(entity \(eid ?? -1))"
    //             print("   ↳ \(nm): \(amt)")
    //         }
    //     }
    // }
// }
