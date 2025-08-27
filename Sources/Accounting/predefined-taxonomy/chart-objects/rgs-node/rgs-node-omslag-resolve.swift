import Foundation

extension Array where Element == RGSNode {
    public func withResolvedOmslagIds(strict: Bool = true) throws -> [RGSNode] {
        let byCode: [String: Int] = Dictionary(uniqueKeysWithValues: self.map { ($0.codes.code, $0.id) })

        var unresolved: [(code: String, omslag: String)] = []
        for n in self {
            if let oms = n.codes.omslag, !oms.isEmpty, byCode[oms] == nil {
                unresolved.append((code: n.codes.code, omslag: oms))
            }
        }
        if strict, !unresolved.isEmpty {
            throw RGSNodeResolutionError.unresolvedOmslag(references: unresolved)
        }

        return try self.map { n in
            let resolvedOmslagId = n.codes.omslag.flatMap { byCode[$0] } ?? n.omslagId

            return try RGSNode(
                id: n.id,
                codes: n.codes,
                links: n.links,
                sorting: n.sorting,
                reference: n.reference,
                labels: n.labels,
                direction: n.direction,
                level: n.level,
                filters: n.filters,
                side: n.side,
                sortingKey: n.sortingKey,
                omslagId: resolvedOmslagId,
                directionSign: n.directionSign
            )
        }
    }
}
