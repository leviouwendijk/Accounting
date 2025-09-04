import Foundation

public enum RGSPrinterError: LocalizedError, Sendable {
    case missingIndex
    public var errorDescription: String? { "RGSPrinter: Missing index on compiled chart." }
}


public struct RGSPresentationSection: Sendable {
    public let key: String
    public let title: String
    public let lines: [RGSPresentationLine]
    
    public init(
        key: String,
        title: String,
        lines: [RGSPresentationLine]
    ) {
        self.key = key
        self.title = title
        self.lines = lines
    }
}

public struct PresentedBalanceTotals: Sendable {
    public let assets: Decimal
    public let equity: Decimal
    public let liabilities: Decimal
    
    public init(
        assets: Decimal,
        equity: Decimal,
        liabilities: Decimal
    ) {
        self.assets = assets
        self.equity = equity
        self.liabilities = liabilities
    }

    public var equityPlusLiabilities: Decimal { equity + liabilities }
}

public enum RGSPrinter {
    public static func printLines(_ title: String, lines: [RGSPresentationLine]) {
        print("\n\(title)")
        print(String(repeating: "—", count: title.count))
        for r in lines {
            let indent = String(repeating: "  ", count: max(0, r.level - 1))
            print("\(indent)• \(r.label)  \(r.amount)")
        }
    }

    public static func printSections(_ title: String, sections: [RGSPresentationSection]) {
        print("\n\(title)")
        print(String(repeating: "—", count: title.count))
        for s in sections {
            print("• \(s.title)")
            print(String(repeating: "—", count: s.title.count))
            for r in s.lines {
                let indent = String(repeating: "  ", count: max(0, r.level - 2))
                print("\(indent)• \(r.label)  \(r.amount)")
            }
            print("")
        }
    }

    public static func presentedSectionTotals(
        chart: CompiledChart,
        bundle: StatementBundle,
        bounds: AlphaBounds = .default,
        omslag: OmslagMode = .apply
    ) throws -> PresentedBalanceTotals {
        let maps  = try RGSAssembler.makeMaps(from: chart)
        let alpha = try RGSAssembler.balanceAlphaSections(
            totals: bundle.totalsById, maps: maps, bounds: bounds
        )
        // resolve real roots for correct display flipping
        let A = try? RGSAssembler.resolveSectionRoot("A", maps: maps).id
        let J = try? RGSAssembler.resolveSectionRoot("J", maps: maps).id
        let K = try? RGSAssembler.resolveSectionRoot("K", maps: maps).id

        func shown(_ raw: Decimal, _ id: Int?) -> Decimal {
            guard let id = id else { return raw }
            return RGSAssembler.present(raw, direction: maps.directionById[id] ?? .debit, mode: omslag)
        }

        let a = shown(alpha.assets,      A)
        let e = shown(alpha.equity,      J)
        let k = shown(alpha.liabilities, K)
        return PresentedBalanceTotals(assets: a, equity: e, liabilities: k)
    }

    public static func printSectionsWithFooters(
        _ title: String,
        sections: [RGSPresentationSection],
        chart: CompiledChart,
        bundle: StatementBundle,
        bounds: AlphaBounds = .default,
        omslag: OmslagMode = .apply
    ) throws {
        let t = try presentedSectionTotals(chart: chart, bundle: bundle, bounds: bounds, omslag: omslag)

        print("\n\(title)")
        print(String(repeating: "—", count: title.count))
        for s in sections {
            print("• \(s.title)")
            print(String(repeating: "—", count: s.title.count))
            for r in s.lines {
                let indent = String(repeating: "  ", count: max(0, r.level - 2))
                print("\(indent)• \(r.label)  \(r.amount)")
            }
            // section footers
            if s.key == "A" { print("  — Subtotal Assets: \(t.assets)") }
            if s.key == "J" { print("  — Subtotal Equity: \(t.equity)") }
            if s.key == "K" { print("  — Subtotal Liabilities: \(t.liabilities)") }
            print("")
        }

        // Bottom summary
        print("== Summary ==")
        print("Subtotal Equity + Liabilities: \(t.equityPlusLiabilities)")
        print()
        print("Check: ( Assets ==  Equity + Liabilities )? → ( \(t.assets) == \(t.equityPlusLiabilities) )")
    }

    public static func printBalanceSidesSummary(
        title: String,
        sections: BalanceAlphaSections,
        maps: RGSAssemblerResult,
        omslag: OmslagMode = .apply
    ) throws {
        // Resolve real root ids to fetch directions for display flipping
        let A = try RGSAssembler.resolveSectionRoot("A", maps: maps).id
        let J = try RGSAssembler.resolveSectionRoot("J", maps: maps).id
        let K = try RGSAssembler.resolveSectionRoot("K", maps: maps).id

        func shown(_ raw: Decimal, _ id: Int) -> Decimal {
            RGSAssembler.present(raw, direction: maps.directionById[id] ?? .debit, mode: omslag)
        }

        let a = shown(sections.assets, A)
        let e = shown(sections.equity, J)
        let l = shown(sections.liabilities, K)

        print("\n\(title)")
        print(String(repeating: "—", count: title.count))
        print("Assets (A)\t\t\(a)")
        print("Equity (J)\t\t\(e)")
        print("Liabilities (K)\t\(l)")
        print("Check: Assets vs Equity+Liabilities → \(a) vs \(e + l)")
        print("Balanced? \(sections.diffRaw == 0 ? "✓" : "✗  diff=\(sections.diffRaw)") )")
    }

    public static func balanceSectionsAlphaOrdered(
        from bundle: StatementBundle,
        using chart: CompiledChart,
        bounds: AlphaBounds = .default,
        dropRootLine: Bool = true,
        includeOtherBucket: Bool = false
    ) throws -> [RGSPresentationSection] {
        let maps  = try RGSAssembler.makeMaps(from: chart)

        // Classify a node by its L2 sorting key (robust for parents and children).
        func classifyByL2(_ id: Int) -> RGSAssembleSection.Balance? {
            guard maps.kindById[id] == .balance,
                  let key = maps.sortKeyById[id], !key.isEmpty else { return nil }
            let l2 = RGSNodeSortingCode(key: key).l2Key(fallbackSide: "B") // e.g. "B.A"
            guard let letter = RGSAssembler.firstLetterSegment(from: l2) else { return nil }
            return RGSAssembler.classifyBalance(letter: letter, bounds: bounds)
        }

        // Find the true BALANS root id (key "B"); if missing, don't drop anything.
        let balansRootId = maps.keyToId["B"]

        // Preserve original inclusion; drop ONLY the BALANS row if requested
        let src = bundle.balance.filter { line in
            guard dropRootLine, let bid = balansRootId else { return true }
            return line.id != bid
        }

        // Stable partition — DO NOT drop unclassified; put them in `other`
        var assets: [RGSPresentationLine] = []
        var equity: [RGSPresentationLine] = []
        var liabs:  [RGSPresentationLine] = []
        var other:  [RGSPresentationLine] = []

        for r in src {
            switch classifyByL2(r.id) {
            case .some(.assets):      assets.append(r)
            case .some(.equity):      equity.append(r)
            case .some(.liabilities): liabs.append(r)
            case .none:               other.append(r)   // keep it; don’t drop
            }
        }

        // Optional safety: assert we didn’t lose rows
        let inCount  = src.count
        let outCount = assets.count + equity.count + liabs.count + other.count
        if inCount != outCount {
            fputs("printer: dropped \(inCount - outCount) line(s)\n", stderr)
        }

        // Build sections (fixed titles; we’re not pulling category labels like “Omrekeningsverschillen”)
        var sections: [RGSPresentationSection] = []
        if !assets.isEmpty { sections.append(.init(key: "A", title: "Assets",      lines: assets)) }
        if !equity.isEmpty { sections.append(.init(key: "J", title: "Equity",      lines: equity)) }
        if !liabs.isEmpty  { sections.append(.init(key: "K", title: "Liabilities", lines: liabs )) }
        if includeOtherBucket, !other.isEmpty { sections.append(.init(key: "-", title: "Other", lines: other)) }

        // Sanity: keep count identical to input (so we know we didn’t drop anything)
        // (Optional) assert(sections.flatMap(\.lines).count == src.count)

        return sections
    }

    public static func balanceSectionsByL2Ordered(
        from bundle: StatementBundle,
        using chart: CompiledChart,
        dropRootLine: Bool = true,
        includeOtherBucket: Bool = false
    ) throws -> [RGSPresentationSection] {
        return try sectionsByL2Ordered(
            lines: bundle.balance,
            side: .balance,
            chart: chart,
            dropRootLine: dropRootLine,
            includeOtherBucket: includeOtherBucket
        )
    }

    public static func incomeSectionsByL2Ordered(
        from bundle: StatementBundle,
        using chart: CompiledChart,
        dropRootLine: Bool = true,
        includeOtherBucket: Bool = false
    ) throws -> [RGSPresentationSection] {
        return try sectionsByL2Ordered(
            lines: bundle.income,
            side: .income,
            chart: chart,
            dropRootLine: dropRootLine,
            includeOtherBucket: includeOtherBucket
        )
    }

    // ------------------------------------------------------------
    // MARK: - Core L2 sectioning (identifier parents for grouping, SortingKey for order)
    // ------------------------------------------------------------

    @inline(__always)
    private static func sectionsByL2Ordered(
        lines: [RGSPresentationLine],
        side: StatementKind,
        chart: CompiledChart,
        dropRootLine: Bool,
        includeOtherBucket: Bool
    ) throws -> [RGSPresentationSection] {
        let maps  = try RGSAssembler.makeMaps(from: chart)   // has sortKeyById + parentById + nameById + keyToId
        let ch    = try chart.ensuringIndex(enrichNodes: true, strict: false)
        guard let _ = ch.index else { throw RGSPrinterError.missingIndex }

        // Build node lookup for quick level checks
        let nodeById = Dictionary(uniqueKeysWithValues: chart.nodes.map { ($0.id, $0) })

        // Root id and side root key
        let rootKey  = (side == .balance) ? "B" : "W"
        let rootId   = maps.keyToId[rootKey]

        // Optionally drop the literal root row from printing
        let src: [RGSPresentationLine] = lines.filter { line in
            guard dropRootLine, let rid = rootId else { return true }
            return line.id != rid
        }

        // Discover L2 anchors dynamically: nodes with level==2 and kind==side
        var anchors: [(id: Int, key: String, title: String)] = []
        for n in chart.nodes where n.level == 2 {
            guard maps.kindById[n.id] == side else { continue }
            let key = maps.sortKeyById[n.id] ?? ""
            let title = maps.nameById[n.id] ?? n.labels.short
            anchors.append((n.id, key, title))
        }
        // Order anchors by SortingKey
        anchors.sort { RGSNodeSortingCode(key: $0.key) < RGSNodeSortingCode(key: $1.key) }

        // Helper: find L2 ancestor by walking identifier parents
        @inline(__always)
        func l2AncestorId(of id: Int) -> Int? {
            var cur = id
            while let p = maps.parentById[cur] {
                if let pn = nodeById[p], pn.level == 2 { return p }
                cur = p
            }
            return nil
        }

        // Group lines under their L2 ancestor
        var bucketByAnchor: [Int: [RGSPresentationLine]] = [:]
        var other: [RGSPresentationLine] = []

        for r in src {
            if let a = l2AncestorId(of: r.id) {
                bucketByAnchor[a, default: []].append(r)
            } else {
                other.append(r)   // keep; malformed/misc nodes end up here
            }
        }

        // Sort each bucket by SortingKey (order only)
        func sortByKey(_ a: RGSPresentationLine, _ b: RGSPresentationLine) -> Bool {
            let ka = maps.sortKeyById[a.id] ?? ""
            let kb = maps.sortKeyById[b.id] ?? ""
            return RGSNodeSortingCode(key: ka) < RGSNodeSortingCode(key: kb)
        }
        for k in bucketByAnchor.keys {
            bucketByAnchor[k]!.sort(by: sortByKey)
        }
        other.sort(by: sortByKey)

        // Emit sections in anchor order; skip empty buckets
        var out: [RGSPresentationSection] = []
        for (anchorId, key, title) in anchors {
            if let lines = bucketByAnchor[anchorId], !lines.isEmpty {
                // section key: for Balance use first letter (A/J/K etc.) if present, else code
                let sectionKey: String = {
                    guard side == .balance, let sk = maps.sortKeyById[anchorId] else { return key }
                    let l2 = RGSNodeSortingCode(key: sk).l2Key(fallbackSide: "B")   // <- String, not Optional
                    if let letter = RGSAssembler.firstLetterSegment(from: l2) {
                        return letter
                    } else {
                        return key
                    }
                }()
                out.append(.init(key: sectionKey, title: title, lines: lines))
            }
        }
        if includeOtherBucket, !other.isEmpty {
            out.append(.init(key: "-", title: "Other", lines: other))
        }
        return out
    }
}
