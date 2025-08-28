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
        equation: BalanceEquation,
        maps: RGSAssemblerResult,
        omslag: OmslagMode = .apply
    ) {
        func shown(_ raw: Decimal, _ id: Int) -> Decimal {
            let dir = maps.directionById[id] ?? .debit
            return RGSAssembler.present(raw, direction: dir, mode: omslag)
        }

        let a = shown(equation.assets.raw, equation.assets.id)
        let e = shown(equation.equity.raw, equation.equity.id)
        let l = shown(equation.liabilities.raw,   equation.liabilities.id)

        print("\n\(title)")
        print(String(repeating: "—", count: title.count))
        print("Assets (A)\t\t\(a)")
        print("Equity (J)\t\t\(e)")
        print("Liabilities (K)\t\(l)")
        print("Check: Assets vs Equity+Liabilities → \(a) vs \(e + l)")
        print("Balanced? \(equation.diffRaw == 0 ? "✓" : "✗  diff=\(equation.diffRaw)") )")
    }
}
