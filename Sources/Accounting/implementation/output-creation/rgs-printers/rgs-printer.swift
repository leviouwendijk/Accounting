import Foundation

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
    public static func sections(
        for kind: StatementKind,
        from bundle: StatementBundle,
        using chart: CompiledChart,
        groupDepth: Int = 2
    ) throws -> [RGSPresentationSection] {
        let maps  = try RGSAssembler.makeMaps(from: chart)
        let ch    = try chart.ensuringIndex(enrichNodes: true, strict: false)
        guard let idx = ch.index else { throw NSError(domain: "printer", code: 1) }
        let labelFor = idx.labelByGroupKey

        let lines = (kind == .balance) ? bundle.balance : bundle.income
        let grouped = Dictionary(grouping: lines) { (r) -> String in
            let key = maps.sortKeyById[r.id] ?? ""
            let parts = key.split(separator: ".")
            return parts.prefix(groupDepth).joined(separator: ".")
        }

        let keys = grouped.keys.sorted {
            RGSNodeSortingCode(key: $0) < RGSNodeSortingCode(key: $1)
        }

        return keys.map { k in
            let title = labelFor[k] ?? k
            let sortedLines = grouped[k]!.sorted {
                let a = maps.sortKeyById[$0.id] ?? ""
                let b = maps.sortKeyById[$1.id] ?? ""
                return RGSNodeSortingCode(key: a) < RGSNodeSortingCode(key: b)
            }
            return .init(key: k, title: title, lines: sortedLines)
        }
    }
}
