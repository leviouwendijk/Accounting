import Foundation

public struct AccountStore: Codable, Sendable {
    /// Canonical map: posting code -> node
    public let byCode: [String: RGSNode]
    /// Optional map: RGS identifier -> node (requires chart index)
    public let byIdentifier: [String: RGSNode]

    public let hierarchyProblemsById: [Int: RGSIdentifierHierarchy.Problem]

    // Build from a full compiled chart (preferred: enables identifier lookups)
    public init(chart: CompiledChart) throws {
        var codeMap: [String: RGSNode] = [:]
        for n in chart.nodes {
            let code = n.codes.code
            if codeMap.updateValue(n, forKey: code) != nil {
                throw AccountStoreError.duplicateCode(code, at: nil)
            }
        }
        var identMap: [String: RGSNode] = [:]

        guard let idx = chart.index else { throw AccountStoreError.compiledChartIndexEmpty }

        // Index provides ident -> node.id
        for (ident, id) in idx.byIdentifier {
            // nodes are typically few enough that building a dict is fine;
            // if you already have a nodeById map elsewhere, reuse it.
            if let node = chart.nodes.first(where: { $0.id == id }) {
                identMap[ident] = node
            }
        }
        self.byCode = codeMap
        self.byIdentifier = identMap

        // NEW: compute hierarchy problems once
        let hier = RGSIdentifierHierarchy.build(from: chart.nodes)
        let problemsById = Dictionary(uniqueKeysWithValues: hier.problems.map { ($0.childId, $0) })
        self.hierarchyProblemsById = problemsById
    }

    // Convenience: build from nodes only (identifier lookups disabled)
    public init(nodes: [RGSNode]) throws {
        var codeMap: [String: RGSNode] = [:]
        for n in nodes {
            let code = n.codes.code
            if codeMap.updateValue(n, forKey: code) != nil {
                throw AccountStoreError.duplicateCode(code, at: nil)
            }
        }

        // Fallback build of problems even without a compiled index
        let hier = RGSIdentifierHierarchy.build(from: nodes)
        let problemsById = Dictionary(uniqueKeysWithValues: hier.problems.map { ($0.childId, $0) })

        self.byCode = codeMap
        self.byIdentifier = [:]
        self.hierarchyProblemsById = problemsById
    }

    // @inlinable
    // public func resolve(_ ref: AccountRef, at loc: SourceLocation?) throws -> RGSNode {
    //     switch ref {
    //     case .code(let s):
    //         if let node = byCode[s] { return node }
    //         // also allow passing an identifier via .code by accident (be forgiving)
    //         if let node = byIdentifier[s] { return node }
    //         throw AccountStoreError.notFound(code: s, at: loc)

    //     case .identifier(let ident):
    //         if let node = byIdentifier[ident] { return node }
    //         throw AccountStoreError.notFound(code: ident, at: loc)

    //     case .path(let segs):
    //         // numeric first segment → posting code
    //         if let first = segs.first,
    //            first.allSatisfy(\.isNumber),
    //            let node = byCode[first] {
    //             return node
    //         }
    //         // legacy: account 10201
    //         if segs.first == "account",
    //            let code = segs.dropFirst().first,
    //            code.allSatisfy(\.isNumber),
    //            let node = byCode[code] {
    //             return node
    //         }
    //         // single non-numeric path segment? treat as identifier if we can
    //         if segs.count == 1, let node = byIdentifier[segs[0]] {
    //             return node
    //         }
    //         throw AccountStoreError.invalidReference(path: segs, at: loc)
    //     }
    // }

    @inlinable
    public func resolve(_ ref: AccountRef, at loc: SourceLocation?) throws -> RGSNode {
        let node: RGSNode
        switch ref {
        case .code(let s):
            if let n = byCode[s] { node = n }
            else if let n = byIdentifier[s] { node = n }  // forgiving
            else { throw AccountStoreError.notFound(code: s, at: loc) }

        case .identifier(let ident):
            if let n = byIdentifier[ident] { node = n }
            else { throw AccountStoreError.notFound(code: ident, at: loc) }

        case .path(let segs):
            if let first = segs.first, first.allSatisfy(\.isNumber), let n = byCode[first] {
                node = n
            } else if segs.first == "account",
                      let code = segs.dropFirst().first,
                      code.allSatisfy(\.isNumber),
                      let n = byCode[code] {
                node = n
            } else if segs.count == 1, let n = byIdentifier[segs[0]] {
                node = n
            } else {
                throw AccountStoreError.invalidReference(path: segs, at: loc)
            }
        }

        // NEW: block nodes with known hierarchy issues
        if let problem = hierarchyProblemsById[node.id] {
            throw AccountStoreError.hierarchyIssue(problem: problem, at: loc)
        }
        return node
    }


    public var all: [RGSNode] { Array(byCode.values) }
    public var count: Int { byCode.count }
}

