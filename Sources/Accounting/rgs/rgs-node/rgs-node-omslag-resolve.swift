import Foundation

public extension Array where Element == RGSNode {
    func withResolvedOmslagIds(byCode: [String: Int]) throws -> [RGSNode] {
        try self.map { n in
            let resolved = n.codes.omslag.flatMap { byCode[$0] } ?? n.omslagId
            return (resolved == n.omslagId) ? n : try n.with(omslagId: resolved)
        }
    }
}
