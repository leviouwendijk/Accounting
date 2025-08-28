import Foundation
import plate

public struct CompiledChart: Sendable, Codable {
    public let name: String                    // "RGS-DutchGAAP-2025 (v3.8)"
    public let version: ChartVersion           // 3.8
    public let nodes: [RGSNode]                // leaf + intermediate + whatever you want (even just leaves)
    public let index: RGSIndex?
    
    internal init(
        name: String,                    // "RGS-DutchGAAP-2025 (v3.8)",
        version: ChartVersion,           // 3.8,
        nodes: [RGSNode],                // leaf + intermediate + whatever you want (even just leaves),
        index: RGSIndex? = nil
    ) {
        self.name = name
        self.version = version
        self.nodes = nodes
        self.index = index
    }

    public init(
        name: String,
        version: ChartVersion,           
        nodes: [RGSNode]
    ) throws {
        let unindexedChart = CompiledChart(name: name, version: version, nodes: nodes, index: nil)
        let indexed = try unindexedChart.ensuringIndex()
        self = indexed
    }

    /// If `index` is nil, derive it from `nodes`; otherwise return self.
    /// This variant also accepts enrichment (resolve parentId/l2Id) and returns a new CompiledChart with enriched nodes.
    public func ensuringIndex(enrichNodes: Bool = false, strict: Bool = false) throws -> CompiledChart {
        if index != nil { return self }

        // Build index (optionally enrich nodes)
        let (builtIndex, enrichedNodes) = try RGSIndex.build(from: nodes, enrichNodes: enrichNodes, strict: strict)

        // If builder returned enriched nodes, use them; otherwise keep original nodes
        let finalNodes = enrichedNodes ?? nodes

        return CompiledChart(name: name, version: version, nodes: finalNodes, index: builtIndex)
    }

    // /// If `index` is nil, derive it from `nodes`; otherwise return self.
    // public func ensuringIndex() throws -> CompiledChart {
    //     if index != nil { return self }
    //     let built = try RGSIndex.build(from: nodes)
    //     return CompiledChart(name: name, version: version, nodes: nodes, index: built)
    // }
}

// public struct Account: Sendable, Codable, Hashable {
//     public let id: Int
//     public let gl: String
//     public let name: String
//     public let rgsIdentifier: String           // store string; resolve to id once on load
// }

