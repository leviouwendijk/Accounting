import Foundation

// public struct AccountStore: Codable, Sendable {
//     public let byCode: [String: RGSAccount]
//     public init(_ accounts: [RGSAccount]) throws {
//         var m: [String:RGSAccount] = [:]
//         for a in accounts {
//             if m.updateValue(a, forKey: a.code) != nil {
//                 throw AccountStoreError.duplicateCode(a.code, at: nil) // ← add at: nil
//             }
//         }
//         self.byCode = m
//     }

//     @inlinable
//     public func resolve(_ ref: AccountRef, at loc: SourceLocation?) throws -> RGSAccount {
//         switch ref {
//         case .code(let s):
//             if let acc = byCode[s] { return acc }
//             throw AccountStoreError.notFound(code: s, at: loc)

//         case .path(let segs):
//             // numeric first segment → code
//             if let first = segs.first, first.allSatisfy(\.isNumber), let acc = byCode[first] {
//                 return acc
//             }
//             // legacy: account 10201
//             if segs.first == "account",
//                let code = segs.dropFirst().first,
//                code.allSatisfy(\.isNumber),
//                let acc = byCode[code] {
//                 return acc
//             }
//             throw AccountStoreError.invalidReference(path: segs, at: loc)
//         }
//     }

//     var all: [RGSAccount] { Array(byCode.values) }
//     var count: Int { byCode.count }
// }

public struct AccountStore: Codable, Sendable {
    /// Canonical map: posting code -> node
    public let byCode: [String: RGSNode]
    /// Optional map: RGS identifier -> node (requires chart index)
    public let byIdentifier: [String: RGSNode]

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
        // Index provides ident -> node.id
        for (ident, id) in chart.index.byIdentifier {
            // nodes are typically few enough that building a dict is fine;
            // if you already have a nodeById map elsewhere, reuse it.
            if let node = chart.nodes.first(where: { $0.id == id }) {
                identMap[ident] = node
            }
        }
        self.byCode = codeMap
        self.byIdentifier = identMap
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
        self.byCode = codeMap
        self.byIdentifier = [:]
    }

    @inlinable
    public func resolve(_ ref: AccountRef, at loc: SourceLocation?) throws -> RGSNode {
        switch ref {
        case .code(let s):
            if let node = byCode[s] { return node }
            // also allow passing an identifier via .code by accident (be forgiving)
            if let node = byIdentifier[s] { return node }
            throw AccountStoreError.notFound(code: s, at: loc)

        case .identifier(let ident):
            if let node = byIdentifier[ident] { return node }
            throw AccountStoreError.notFound(code: ident, at: loc)

        case .path(let segs):
            // numeric first segment → posting code
            if let first = segs.first,
               first.allSatisfy(\.isNumber),
               let node = byCode[first] {
                return node
            }
            // legacy: account 10201
            if segs.first == "account",
               let code = segs.dropFirst().first,
               code.allSatisfy(\.isNumber),
               let node = byCode[code] {
                return node
            }
            // single non-numeric path segment? treat as identifier if we can
            if segs.count == 1, let node = byIdentifier[segs[0]] {
                return node
            }
            throw AccountStoreError.invalidReference(path: segs, at: loc)
        }
    }

    public var all: [RGSNode] { Array(byCode.values) }
    public var count: Int { byCode.count }
}

