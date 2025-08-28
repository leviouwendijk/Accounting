import Foundation

public struct RGSIndex: Hashable, Sendable, Codable {
    public let byIdentifier: [String:Int]     // "BLimBanRba" -> node.id
    public let bySortKey: [String:Int]        // "A.F.0104000" -> node.id
    public let labelByGroupKey: [String:String] // groupKey (any level) -> labelShort
    public let byReference: [String:Int]    // in rare cases of referentienummer use
    
    public init(
        byIdentifier: [String:Int],
        bySortKey: [String:Int],    
        labelByGroupKey: [String:String],
        byReference: [String:Int]
    ) {
        self.byIdentifier = byIdentifier
        self.bySortKey = bySortKey
        self.labelByGroupKey = labelByGroupKey
        self.byReference = byReference
    }
}

// // mock version of a new structured account key
// public struct LocalAccountKey: Hashable, Sendable, Codable {
//     public let section: String // level 1 : BALANS
//     public let set: String // level 2 : Immateriele Vaste Activa
//     public let group: String // level 3 : categorical
//     public let account: String // level 4
//     public let subaccount: String? // level 5
// }

// public struct LocalChartIndex: Sendable, Codable {
//     public let localAccountToCode: [LocalAccountKey: String] // "key: assets.fixed_tangible.vehicles -> "BMva.."
//     public let localAccountToId: [LocalAccountKey: Int]
// }

// Small error wrapper for collisions while building the index
public enum CompiledChartIndexError: Error, CustomStringConvertible, Sendable {
    case duplicateIdentifier(String)
    case duplicateSortKey(String)
    case duplicateReference(String)

    public var description: String {
        switch self {
        case .duplicateIdentifier(let k): return "Duplicate identifier: \(k)"
        case .duplicateSortKey(let k):    return "Duplicate sort key: \(k)"
        case .duplicateReference(let k):  return "Duplicate reference: \(k)"
        }
    }
}

public extension RGSIndex {
    /// Build an index directly from nodes.
    static func build(from nodes: [RGSNode]) throws -> RGSIndex {
        var byIdentifier: [String:Int] = [:]   // codes.code → id
        var bySortKey:   [String:Int] = [:]    // xlsx.cachedSortingKey → id
        var labelByKey:  [String:String] = [:] // cachedSortingKey (any level) → label.short
        var byReference: [String:Int] = [:]    // xlsx.reference → id

        for n in nodes {
            // identifier (RGS referentiecode)
            if byIdentifier.updateValue(n.id, forKey: n.codes.code) != nil {
                throw CompiledChartIndexError.duplicateIdentifier(n.codes.code)
            }

            if let x = n.xlsx {
                // sort key (we have both sorting.code and cachedSortingKey in the model)
                let key = x.cachedSortingKey
                if bySortKey.updateValue(n.id, forKey: key) != nil {
                    throw CompiledChartIndexError.duplicateSortKey(key)
                }
                // label for any grouping key (we map every node's own key to its short label)
                if labelByKey[key] == nil { labelByKey[key] = n.labels.short }
                // reference if present
                if let ref = x.reference {
                    if byReference.updateValue(n.id, forKey: ref) != nil {
                        throw CompiledChartIndexError.duplicateReference(ref)
                    }
                }
            }
        }

        return RGSIndex(
            byIdentifier: byIdentifier,
            bySortKey: bySortKey,
            labelByGroupKey: labelByKey,
            byReference: byReference
        )
    }
}
