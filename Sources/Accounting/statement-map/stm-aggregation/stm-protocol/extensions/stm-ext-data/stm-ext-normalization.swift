import Foundation

public extension StatementAggregating {
    @inlinable
    func normalize(_ e: ResolvedEntry, _ line: ResolvedLine, accounts: AccountStore) throws -> NormalizedPosting {
        let acc = try accounts.byCode[line.account.code] ?? { throw AccountStoreError.notFound(code: line.account.code, at: nil) }()
        // amount as signed: debit => +, credit => − (you already use this for balance assertions) :contentReference[oaicite:3]{index=3}
        let signed = (line.direction == .debit ? +line.amount : -line.amount)

        let dims: DimensionSlice = [
            .entity:       .entity(line.entity),
            .entityClass:  .text(line.entity.class),
            .entityFamily: .text(line.entity.family),
            .entityAlias:  .text(line.entity.alias.string),
        ]

        let rgs = acc.identifiers.rgs.isEmpty ? acc.code : acc.identifiers.rgs

        return .init(
            period: e.date,
            amount: signed,
            direction: line.direction,
            rgsCode: rgs,
            omslag:  acc.identifiers.omslag,
            rgsLevel: acc.level,
            naturalSide: acc.direction,
            dims: dims
        )
    }
}
