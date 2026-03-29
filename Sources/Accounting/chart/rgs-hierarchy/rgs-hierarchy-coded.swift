import Foundation

// (feature): possible expansion, for unmapped / unresolved codes:
// note: run ec with hierarchy diagnostics first

// public struct RGSHierarchyOverrides: Sendable, Codable {
//     public let parentCodeByChildCode: [String: String]

//     public init(
//         parentCodeByChildCode: [String: String] = [:]
//     ) {
//         self.parentCodeByChildCode = parentCodeByChildCode
//     }

//     public static let rgsDefault = RGSHierarchyOverrides(
//         parentCodeByChildCode: [
//             // child: parent
//             "BLasOlsIlgBet": "BLasOlsIlg",
//             "BLasOlsIlgSto": "BLasOlsIlg",
//             "BLasSohSohBet": "BLasSohSoh",
//             "BLasSohSohSto": "BLasSohSoh",
//             "BMvaHuuCaeOvm": "BMvaHuuCae",
//             "BMvaHuuCuhOvm": "BMvaHuuCuh",
//             "BSchOdvKlo": "BSchOdv",
//             "BVrdVioVic": "BVrdVio",
//             "BVrzOihOrtTev": "BVrzOihOrt",
//         ]
//     )
// }

// public static func makeMaps(
//     from ch: CompiledChart,
//     overrides: RGSHierarchyOverrides = .rgsDefault
// ) throws -> RGSAssemblerResult
// ....

public enum RGSIdentifierHierarchy {
    public struct Problem: Sendable, Codable, CustomStringConvertible {
        public enum Kind: Sendable, Codable { case noParent(level: UInt8), multipleParents(level: UInt8, candidates: [String]) }
        public let childId: Int
        public let childCode: String
        public let childLevel: UInt8
        public let kind: Kind

        public var description: String {
            switch kind {
            case .noParent(let lvl):                 return "no parent at level \(lvl) for \(childCode)"
            case .multipleParents(let lvl, let cs):  return "multiple parents at level \(lvl) for \(childCode): \(cs.joined(separator: ","))"
            }
        }
    }

    public struct Result: Sendable {
        public let parentById: [Int:Int?]     // child → parent (nil for roots)
        public let problems: [Problem]
    }

    /// Build child→parent strictly from:
    ///   - code prefix: parent.code is a proper prefix of child.code
    ///   - level rule:  parent.level == child.level - 1
    public static func build(from nodes: [RGSNode]) -> Result {
        let byLevel = Dictionary(grouping: nodes, by: { $0.level })
        var parentById: [Int:Int?] = [:]
        var problems: [Problem] = []

        for n in nodes {
            if n.level <= 1 { parentById[n.id] = nil; continue }
            let wantLevel = n.level &- 1
            let peers = byLevel[wantLevel] ?? []
            let cands = peers.filter { n.codes.code.hasPrefix($0.codes.code) && $0.id != n.id }

            switch cands.count {
            case 0:
                problems.append(.init(childId: n.id, childCode: n.codes.code, childLevel: n.level, kind: .noParent(level: wantLevel)))
                parentById[n.id] = nil
            case 1:
                parentById[n.id] = cands[0].id
            default:
                let best = cands.max(by: { $0.codes.code.count < $1.codes.code.count })!
                problems.append(.init(childId: n.id, childCode: n.codes.code, childLevel: n.level,
                                      kind: .multipleParents(level: wantLevel, candidates: cands.map { $0.codes.code }.sorted())))
                parentById[n.id] = best.id
            }
        }
        return .init(parentById: parentById, problems: problems)
    }
}

