import Accounting
import Foundation

extension RGSAssembler {
    public static func makeMaps(from ch: CompiledChart) throws -> RGSAssemblerResult {
        guard let index = ch.index else { throw RGSAssemblerError.missingIndex }

        let nodes = ch.nodes

        // sortingkey for order only 
        var sortKeyById: [Int:String] = [:]
        for n in nodes {
            let key = n.xlsx?.sorting.key ?? n.codes.code
            sortKeyById[n.id] = key
        }

        let directionById = Dictionary(uniqueKeysWithValues: nodes.compactMap { n in
            n.direction.map { (n.id, $0) }
        })

        let kindById: [Int: StatementKind] = Dictionary(uniqueKeysWithValues: nodes.map { n in
            (n.id, (n.side == .balance ? .balance : .income))
        })

        let keyToId = index.bySortKey    // existing compiled index

        // parent by rgs identifier
        let hier = RGSIdentifierHierarchy.build(from: nodes)
        let parentById: [Int:Int] = Dictionary(uniqueKeysWithValues:
            hier.parentById.compactMap { (child, parent) in parent.map { (child, $0) } }
        )

        return RGSAssemblerResult(
            totalsById: [:],                    // filled later
            kindById: kindById,
            sortKeyById: sortKeyById,
            directionById: directionById,
            parentById: parentById,
            keyToId: keyToId,
            nameById: Dictionary(uniqueKeysWithValues: nodes.map{ ($0.id, $0.labels.short) })
        )
    }
}
