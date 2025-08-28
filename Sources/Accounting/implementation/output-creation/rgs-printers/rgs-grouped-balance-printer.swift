import Foundation

// Group the Balance by SortingKey L2 prefixes, using RGS labels for headers.
public func printGroupedBalance(
    _ title: String,
    bundle: StatementBundle,
    chart: CompiledChart
) throws {
    // 1) Maps & labels
    let maps  = try RGSAssembler.makeMaps(from: chart)               // id -> sortKey
    let ch = try chart.ensuringIndex(enrichNodes: true, strict: false)
    guard let idx = ch.index else { throw RGSPrinterError.missingIndex }
    let labelForPrefix = idx.labelByGroupKey                          // "B.XX" -> "Header"

    // 2) Group lines by L2 prefix of their sort key (e.g., "B.A", "B.E", "B.L")
    let grouped = Dictionary(grouping: bundle.balance) { (line) -> String in
        let key = maps.sortKeyById[line.id] ?? ""
        let parts = key.split(separator: ".")
        return parts.prefix(2).joined(separator: ".")                 // L2 prefix
    }

    // 3) Deterministic section order by SortingCode comparator
    let sectionKeys = grouped.keys.sorted {
        RGSNodeSortingCode(key: $0) < RGSNodeSortingCode(key: $1)
    }

    // 4) Print
    print("\n\(title)")
    print(String(repeating: "—", count: title.count))

    for prefix in sectionKeys {
        let header = labelForPrefix[prefix] ?? prefix
        print("• \(header)")
        print(String(repeating: "—", count: header.count))

        // lines inside a section in SortingCode order; indent under the L2 node
        let lines = grouped[prefix]!.sorted {
            let ka = maps.sortKeyById[$0.id] ?? ""
            let kb = maps.sortKeyById[$1.id] ?? ""
            return RGSNodeSortingCode(key: ka) < RGSNodeSortingCode(key: kb)
        }

        for r in lines {
            let indent = String(repeating: "  ", count: max(0, r.level - 2))
            print("\(indent)• \(r.label)  \(r.amount)")
        }
        print("") // blank line between sections
    }
}
