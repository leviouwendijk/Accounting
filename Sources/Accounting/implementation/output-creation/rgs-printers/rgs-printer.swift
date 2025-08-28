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

public enum RGSPrinter {
    // Simple printers (keep them minimal and public)
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

    /// Sections in A → J → K order with nested lines sorted by RGS comparator.
    public static func balanceSectionsAlphaOrdered(
        from bundle: StatementBundle,
        using chart: CompiledChart,
        bounds: AlphaBounds = .default,
        dropRootLine: Bool = true
    ) throws -> [RGSPresentationSection] {
        // Maps & labels
        let maps  = try RGSAssembler.makeMaps(from: chart)
        let ch    = try chart.ensuringIndex(enrichNodes: true, strict: false)
        guard let idx = ch.index else { throw SectioningError.missingIndex }
        let labels = idx.labelByGroupKey

        // Precompute section by id (A/J/K) for balance nodes only
        var bucketById: [Int: RGSAssembleSection.Balance] = [:]
        for (id, key) in maps.sortKeyById {
            guard maps.kindById[id] == .balance else { continue }
            if let letter = RGSAssembler.firstLetterSegment(from: key),
               let sec = RGSAssembler.classifyBalance(letter: letter, bounds: bounds) {
                bucketById[id] = sec
            }
        }

        // Partition the bundle’s Balance lines
        let allLines = bundle.balance
        let parts: [RGSAssembleSection.Balance: [RGSPresentationLine]] =
            Dictionary(grouping: allLines) { bucketById[$0.id] ?? .assets } // default won’t surface if filtered below

        // Keep only A/J/K in this order
        let order: [RGSAssembleSection.Balance] = [.assets, .equity, .liabilities]
        var sections: [RGSPresentationSection] = []

        for sec in order {
            guard var lines = parts[sec] else { continue }
            if dropRootLine { lines.removeAll { $0.level == 1 } }

            // Sort lines by sorting key
            lines.sort { a, b in
                let ka = maps.sortKeyById[a.id] ?? ""
                let kb = maps.sortKeyById[b.id] ?? ""
                return RGSNodeSortingCode(key: ka) < RGSNodeSortingCode(key: kb)
            }

            guard !lines.isEmpty else { continue }

            // Title from the A/J/K group node label if present; fall back to enum name
            let letter = (sec == .assets ? "A" : sec == .equity ? "J" : "K")
            let title  = labels["B.\(letter)"] ?? labels[letter] ??
                         (sec == .assets ? "Assets" : sec == .equity ? "Equity" : "Liabilities")

            sections.append(.init(key: letter, title: title, lines: lines))
        }

        return sections
    }
}
