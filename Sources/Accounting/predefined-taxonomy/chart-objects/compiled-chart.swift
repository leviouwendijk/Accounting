import Foundation
import plate

public struct CompiledChart: Sendable, Codable {
    public let name: String                    // "RGS-DutchGAAP-2025 (v3.8)"
    public let version: ChartVersion           // 3.8
    public let nodes: [RGSNode]                // leaf + intermediate + whatever you want (even just leaves)
    public let index: RGSIndex?
    
    public init(
        name: String,                    // "RGS-DutchGAAP-2025 (v3.8)",
        version: ChartVersion,           // 3.8,
        nodes: [RGSNode],                // leaf + intermediate + whatever you want (even just leaves),
        index: RGSIndex?
    ) {
        self.name = name
        self.version = version
        self.nodes = nodes
        self.index = index
    }
}

// public struct Account: Sendable, Codable, Hashable {
//     public let id: Int
//     public let gl: String
//     public let name: String
//     public let rgsIdentifier: String           // store string; resolve to id once on load
// }
