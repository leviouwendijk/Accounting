import Foundation

// public extension StatementAggregating {
//     @inlinable
//     func normalize(_ e: ResolvedEntry, _ line: ResolvedLine, accounts: AccountStore) throws -> NormalizedPosting {
//         let acc = try accounts.byCode[line.account.code] ?? { throw AccountStoreError.notFound(code: line.account.code, at: nil) }()
//         // amount as signed: debit => +, credit => − (you already use this for balance assertions) :contentReference[oaicite:3]{index=3}
//         let signed = (line.direction == .debit ? +line.amount : -line.amount)

//         let dims: DimensionSlice = [
//             .entity:       .entity(line.entity),
//             .entityClass:  .text(line.entity.class),
//             .entityFamily: .text(line.entity.family),
//             .entityAlias:  .text(line.entity.alias.string),
//         ]

//         let rgs = acc.identifiers.rgs.isEmpty ? acc.code : acc.identifiers.rgs

//         return .init(
//             period: e.date,
//             amount: signed,
//             direction: line.direction,
//             rgsCode: rgs,
//             omslag:  acc.identifiers.omslag,
//             rgsLevel: acc.level,
//             naturalSide: acc.direction,
//             dims: dims
//         )
//     }
// }

public extension StatementAggregating {
    @inlinable
    func normalize(
        _ e: ResolvedEntry,
        _ line: ResolvedLine,
        accounts: AccountStore
    ) throws -> NormalizedPosting {
        // AccountStore is now node-backed: byCode[String] -> RGSNode
        guard let node = accounts.byCode[line.account.code] else {
            throw AccountStoreError.notFound(code: line.account.code, at: nil)
        }
        // We aggregate only leaf/postables; enforce it early
        precondition(node.postable, "normalize: node \(node.codes.code) must be postable")
        guard let natural = node.direction else {
            // For postables this should exist (invariants guarantee it for XBRL,
            // and XLSX fallback requires a direction). Fail loudly if not.
            throw RGSNodeInvariantError.missingDirectionForPostable(code: node.codes.code)
        }

        // debit => +, credit => − (your previous semantics)
        let signed = (line.direction == .debit ? +line.amount : -line.amount)

        let dims: DimensionSlice = [
            .entity:       .entity(line.entity),
            .entityClass:  .text(line.entity.class),
            .entityFamily: .text(line.entity.family),
            .entityAlias:  .text(line.entity.alias.string),
        ]

        return .init(
            period:     e.date,
            amount:     signed,
            direction:  line.direction,
            rgsCode:    node.codes.code,       // ← identifier string (“B…”/“W…”, the new canonical)
            omslag:     node.codes.omslag,     // ← optional alt-presentation identifier
            rgsLevel:   Int(node.level),       // ← UInt8 → Int
            naturalSide: natural,              // ← Direction (non-optional here)
            dims:       dims
        )
    }
}
