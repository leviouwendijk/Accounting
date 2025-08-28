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

    /// Partition Balance lines into A → J → K sections while preserving the
    /// original assembled order. Section titles are fixed ("Assets/Equity/Liabilities").
    public static func balanceSectionsAlphaOrdered(
        from bundle: StatementBundle,
        using chart: CompiledChart,
        bounds: AlphaBounds = .default,
        dropRootLine: Bool = true
    ) throws -> [RGSPresentationSection] {
        let maps  = try RGSAssembler.makeMaps(from: chart)

        // helper to classify a line id into a bucket
        func bucket(_ id: Int) -> RGSAssembleSection.Balance? {
            guard maps.kindById[id] == .balance,
                  let key = maps.sortKeyById[id],
                  let letter = RGSAssembler.firstLetterSegment(from: key)
            else { return nil }
            return RGSAssembler.classifyBalance(letter: letter, bounds: bounds)
        }

        // preserve original order: stable partition the already-assembled list
        let src = bundle.balance.filter { !dropRootLine || $0.level > 1 }

        var assets: [RGSPresentationLine] = []
        var equity: [RGSPresentationLine] = []
        var liabs:  [RGSPresentationLine] = []
        for r in src {
            switch bucket(r.id) {
            case .some(.assets):      assets.append(r)
            case .some(.equity):      equity.append(r)
            case .some(.liabilities): liabs.append(r)
            default:                  break // skip anything we can't classify cleanly
            }
        }

        // no re-sorting; we keep the nested rollups exactly as assembled
        var sections: [RGSPresentationSection] = []
        if !assets.isEmpty { sections.append(.init(key: "A", title: "Assets",      lines: assets)) }
        if !equity.isEmpty { sections.append(.init(key: "J", title: "Equity",      lines: equity)) }
        if !liabs.isEmpty  { sections.append(.init(key: "K", title: "Liabilities", lines: liabs )) }
        return sections
    }
}
