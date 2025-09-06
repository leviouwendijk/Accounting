import Foundation

public enum RGSPrinter {
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


    public static func computeBalanceByL2Sections(
        bundle: StatementBundle,
        chart: CompiledChart,
        equityCode: String = "BEiv",
        includeOtherBucket: Bool = false
    ) throws -> RGSBalanceBucketsOutput {

        let maps  = try RGSAssembler.makeMaps(from: chart)              // id->sortKey/dir/parent, etc.
        let nodes = chart.nodes
        // let nodeById = Dictionary(uniqueKeysWithValues: nodes.map { ($0.id, $0) })
        let codeById = Dictionary(uniqueKeysWithValues: nodes.map { ($0.id, $0.codes.code) })
        let levelById: [Int: UInt8] = Dictionary(uniqueKeysWithValues: nodes.map { ($0.id, $0.level) })

        // Analytics (L2 buckets + presented subtotals) available in bundle, else compute now.
        // (You already compute these in assembler and tuck them into the bundle.) :contentReference[oaicite:2]{index=2}
        let analytics: BundleAnalytics = try bundle.analytics ?? {
            let l2  = try RGSAssembler.makeL2Buckets(chart: chart, defaultEquityCode: equityCode)
            let tot = try RGSAssembler.presentedTotalsByL2(chart: chart, bundle: bundle, buckets: l2, omslag: .apply)
            return BundleAnalytics(l2Buckets: l2, l2Totals: tot)
        }()

        let buckets = analytics.l2Buckets
        let assetsAnchorSet      = Set(buckets.assets)
        let liabilitiesAnchorSet = Set(buckets.liabilities)
        let equityAnchor         = buckets.equity

        @inline(__always)
        func l2AncestorId(of id: Int) -> Int? {
            var cur: Int? = id
            while let c = cur {
                if levelById[c] == 2 { return c }
                cur = maps.parentById[c]
            }
            return nil
        }

        @inline(__always)
        func relativeIndent(of id: Int, anchorId: Int?) -> Int {
            guard let anchor = anchorId else { return max(0, Int((levelById[id] ?? 1)) - 1) }
            var depth = 0, cur: Int? = id
            while let c = cur, c != anchor {
                depth += 1
                cur = maps.parentById[c]
            }
            return max(0, depth)
        }

        // Partition bundle.balance lines by L2 anchor
        var assetsLines: [RGSBalanceBucketsOutput.Line] = []
        var equityLines: [RGSBalanceBucketsOutput.Line] = []
        var liabilitiesLines: [RGSBalanceBucketsOutput.Line] = []
        var otherLines: [RGSBalanceBucketsOutput.Line] = []

        for r in bundle.balance { // already "presented" amounts from your assembler’s `linesFor` :contentReference[oaicite:3]{index=3}
            guard let anc = l2AncestorId(of: r.id) else {
                if includeOtherBucket {
                    otherLines.append(.init(
                        id: r.id, code: codeById[r.id] ?? "", label: r.label,
                        amount: r.amount, level: Int(r.level),
                        relativeIndent: max(0, Int((levelById[r.id] ?? 1)) - 1)
                    ))
                }
                continue
            }
            // classify
            if let eq = equityAnchor, anc == eq {
                equityLines.append(.init(
                    id: r.id, code: codeById[r.id] ?? "", label: r.label,
                    amount: r.amount, level: Int(r.level),
                    relativeIndent: relativeIndent(of: r.id, anchorId: eq)
                ))
            } else if assetsAnchorSet.contains(anc) {
                let anchor = assetsAnchorSet.first   // for indent reference
                assetsLines.append(.init(
                    id: r.id, code: codeById[r.id] ?? "", label: r.label,
                    amount: r.amount, level: Int(r.level),
                    relativeIndent: relativeIndent(of: r.id, anchorId: anchor)
                ))
            } else if liabilitiesAnchorSet.contains(anc) {
                let anchor = liabilitiesAnchorSet.first
                liabilitiesLines.append(.init(
                    id: r.id, code: codeById[r.id] ?? "", label: r.label,
                    amount: r.amount, level: Int(r.level),
                    relativeIndent: relativeIndent(of: r.id, anchorId: anchor)
                ))
            } else if includeOtherBucket {
                otherLines.append(.init(
                    id: r.id, code: codeById[r.id] ?? "", label: r.label,
                    amount: r.amount, level: Int(r.level),
                    relativeIndent: max(0, Int((levelById[r.id] ?? 1)) - 1)
                ))
            }
        }

        // Sort each bucket by SortingKey (same as your printer does)
        func sortByKey(_ a: RGSBalanceBucketsOutput.Line, _ b: RGSBalanceBucketsOutput.Line) -> Bool {
            let ka = maps.sortKeyById[a.id] ?? ""
            let kb = maps.sortKeyById[b.id] ?? ""
            return RGSNodeSortingCode(key: ka) < RGSNodeSortingCode(key: kb)
        }
        assetsLines.sort(by: sortByKey)
        equityLines.sort(by: sortByKey)
        liabilitiesLines.sort(by: sortByKey)
        otherLines.sort(by: sortByKey)

        // Sections + subtotals (presented)
        let t = analytics.l2Totals
        let assets      = assetsLines.isEmpty      ? nil : RGSBalanceBucketsOutput.Section(title: "Assets",      lines: assetsLines,      subtotal: t.assets)
        let equity      = equityLines.isEmpty      ? nil : RGSBalanceBucketsOutput.Section(title: "Equity",      lines: equityLines,      subtotal: t.equity)
        let liabilities = liabilitiesLines.isEmpty ? nil : RGSBalanceBucketsOutput.Section(title: "Liabilities", lines: liabilitiesLines, subtotal: t.liabilities)
        let other       = otherLines.isEmpty       ? nil : RGSBalanceBucketsOutput.Section(title: "Other",       lines: otherLines,       subtotal: nil)

        return RGSBalanceBucketsOutput(
            assets: assets, equity: equity, liabilities: liabilities, other: other,
            summary: (t.assets, t.equity, t.liabilities)
        )
    }

    public static func printBalanceByL2Buckets(
        _ title: String,
        bundle: StatementBundle,
        chart: CompiledChart,
        equityCode: String = "BEiv",
        includeOtherBucket: Bool = false
    ) throws {
        let s = try computeBalanceByL2Sections(
            bundle: bundle, chart: chart,
            equityCode: equityCode, includeOtherBucket: includeOtherBucket
        )

        func printSection(_ sec: RGSBalanceBucketsOutput.Section?) {
            guard let sec = sec else { return }
            print("• \(sec.title)")
            print(String(repeating: "—", count: sec.title.count))
            for r in sec.lines {
                let indent = String(repeating: "  ", count: r.relativeIndent)
                print("\(indent)• \(r.label)  \(r.amount)")
            }
            if let st = sec.subtotal { print("  — Subtotal \(sec.title): \(st)") }
            print("")
        }

        print("\n\(title)")
        print(String(repeating: "—", count: title.count))
        printSection(s.assets)
        printSection(s.equity)
        printSection(s.liabilities)
        if includeOtherBucket { printSection(s.other) }

        if let sum = s.summary {
            let ajk = sum.equity + sum.liabilities
            print("== Summary ==")
            print("Subtotal Equity + Liabilities: \(ajk)")
            print("\nCheck: ( Assets ==  Equity + Liabilities )? → ( \(sum.assets) == \(ajk) )")
        }
    }

    public static func incomeSections(
        bundle: StatementBundle,
        chart: CompiledChart,
        omitLevel1Root: Bool = true
    ) throws -> [RGSPresentationSection] {
        // Map id -> level so we can hide only the L1 header node(s)
        let levelById: [Int: UInt8] = Dictionary(uniqueKeysWithValues: chart.nodes.map { ($0.id, $0.level) })

        // Keep EXACT ordering and amounts from bundle.income.
        // Only drop lines whose node.level == 1 when omitLevel1Root is true.
        let lines: [RGSPresentationLine] = bundle.income.filter { line in
            guard omitLevel1Root, let lvl = levelById[line.id] else { return true }
            return lvl != 1
        }

        // Return a single section; renderer decides indentation (e.g. L2 → indent 0).
        return [
            RGSPresentationSection(
                key: "income",
                title: "Income",
                lines: lines
            )
        ]
    }
}

public func printBalanceByL2Buckets(
    _ title: String,
    bundle: StatementBundle,
    chart: CompiledChart,
    equityCode: String,
    includeOtherBucket: Bool,
    showEntityBreakdown: Bool,
    entities: EntityStore,
    minAbs: Decimal = 0
) throws {
    // 1) Keep your refactored balance printer exactly as-is
    try RGSPrinter.printBalanceByL2Buckets(
        title,
        bundle: bundle,
        chart: chart,
        equityCode: equityCode,
        includeOtherBucket: includeOtherBucket
    )

    // 2) Inline entity breakdown (unchanged behaviour)
    guard showEntityBreakdown, let eb = bundle.entity?.byAccount else { return }

    // entity id index is a PROPERTY (stable ids)
    let idx = entities.idIndex

    // entity id -> display name (prefer configured displayName, else alias string)
    var idToName: [Int?: String] = [nil: "(unassigned)"]
    for (key, id) in idx {
        let name = entities.byFull[key]?.displayName ?? key.alias.string
        idToName[id] = name
    }

    // quick map: account id -> RGS code
    let codeById: [Int:String] = Dictionary(uniqueKeysWithValues: chart.nodes.map { ($0.id, $0.codes.code) })

    print("\nEntity breakdown (inline)")
    print("———————————————————————")

    // iterate in the SAME order as the presented balance
    for line in bundle.balance {
        let accId = line.id
        guard let byEnt = eb[accId], !byEnt.isEmpty else { continue }

        let total = byEnt.values.reduce(Decimal(0), +)
        let absTotal = (total < 0 ? -total : total)
        if minAbs > 0, absTotal < minAbs { continue }

        let code = codeById[accId] ?? ""
        print("• \(line.label) [\(code)]  \(total)")

        for (eid, amt) in byEnt.sorted(by: { ($0.key ?? 0) < ($1.key ?? 0) }) where amt != 0 {
            let absAmt = (amt < 0 ? -amt : amt)
            if minAbs > 0, absAmt < minAbs { continue }
            let nm = idToName[eid] ?? "(entity \(eid ?? -1))"
            print("   ↳ \(nm): \(amt)")
        }
    }
}

