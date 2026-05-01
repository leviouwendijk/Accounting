import Accounting
import Foundation

// kept around for older debug method
extension RGSAssembler {
    /// Deterministic roll-up: climb SortingKey prefixes.
    /// Works even when parentId links are missing or partial.
    public static func rollupBySortingKey(
        _ seed: [Int: Decimal],
        idToKey: [Int: String],
        keyToId: [String: Int]
    ) -> [Int: Decimal] {
        var totals = seed
        for (leafId, amt) in seed where amt != 0 {
            guard let key = idToKey[leafId], !key.isEmpty else { continue }
            var curKey: String? = key
            while let k = curKey {
                // go to parent prefix
                guard let pk = RGSNodeSortingCode(key: k).parentKeyString, !pk.isEmpty else { break }
                if let pid = keyToId[pk] {
                    totals[pid, default: 0] += amt
                    curKey = pk
                } else {
                    // stop if parent prefix not mapped (should be rare)
                    break
                }
            }
        }
        return totals
    }
}

// replaced with newer version
// now we roll up by rgs code id

    // public static func makeMaps(from chart: CompiledChart) throws -> RGSAssemblerResult {
    //     let ch = try chart.ensuringIndex(enrichNodes: true, strict: false)
    //     guard let idx = ch.index else { throw RGSAssemblerError.missingIndex }

    //     var kindById: [Int: StatementKind] = [:]
    //     var sortKeyById: [Int: String] = [:]
    //     var directionById: [Int: Direction] = [:]
    //     var parentById: [Int: Int] = [:]
    //     var nameById: [Int: String] = [:]

    //     for n in ch.nodes {
    //         if let x = n.xlsx {
    //             let key = x.cachedSortingKey
    //             sortKeyById[n.id] = key
    //             if let pid = x.links.parentId { parentById[n.id] = pid }
    //         }
    //         directionById[n.id] = n.direction
    //         nameById[n.id] = n.labels.short
    //         if n.codes.code.hasPrefix("B") { kindById[n.id] = .balance }
    //         else if n.codes.code.hasPrefix("W") { kindById[n.id] = .income }
    //     }

    //     return .init(
    //         totalsById: [:],
    //         kindById: kindById,
    //         sortKeyById: sortKeyById,
    //         directionById: directionById,
    //         parentById: parentById,
    //         keyToId: idx.bySortKey,                 // from the index (key -> id)
    //         nameById: nameById
    //     )
    // }


