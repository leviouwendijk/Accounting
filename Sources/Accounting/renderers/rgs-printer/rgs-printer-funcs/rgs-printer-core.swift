import Foundation

public extension RGSPrinter {
    @inline(__always)
    static func graphDepth(of id: Int, parentById: [Int:Int]) -> Int {
        var d = 1, cur = id
        while let p = parentById[cur] { d += 1; cur = p }
        return d
    }

    /// Return the node's own id if it's level 2; otherwise the nearest ancestor at level 2.
    @inline(__always)
    static func l2AncestorId(
        of id: Int,
        parentById: [Int:Int],
        nodeById: [Int:RGSNode]
    ) -> Int? {
        if let n = nodeById[id], n.level == 2 { return id }
        var cur = id
        while let p = parentById[cur] {
            if let n = nodeById[p], n.level == 2 { return p }
            cur = p
        }
        return nil
    }

    /// Indent relative to an anchor. If anchor is nil, indent from top (level 1).
    @inline(__always)
    static func relativeIndent(for lineId: Int, anchorId: Int?, parentById: [Int:Int]) -> Int {
        guard let aid = anchorId else { return max(0, graphDepth(of: lineId, parentById: parentById) - 1) }
        let dl = graphDepth(of: lineId, parentById: parentById)
        let da = graphDepth(of: aid,   parentById: parentById)
        return max(0, dl - da)
    }

    @inline(__always)
    static func sortKey(for id: Int, _ maps: RGSAssemblerResult) -> String {
        maps.sortKeyById[id] ?? ""
    }

    static func printLines(
        _ title: String,
        lines: [StatementLine],
        chart: CompiledChart
    ) throws {
        let maps = try RGSAssembler.makeMaps(from: chart)
        print("\n\(title)")
        print(String(repeating: "—", count: title.count))
        for r in lines {
            let indent = String(repeating: "  ", count: max(0, graphDepth(of: r.id, parentById: maps.parentById) - 1))
            print("\(indent)• \(r.label)  \(r.amount)")
        }
    }
}
