import Foundation

public struct NormalizedPosting: Sendable {
    public let period: DateSpecification
    public let amount: Decimal
    public let direction: Direction
    public let rgsCode: String
    public let omslag: String?
    public let rgsLevel: Int?
    public let naturalSide: Direction?
    public let dims: DimensionSlice
    
    public init(
        period: DateSpecification,
        amount: Decimal,
        direction: Direction,
        rgsCode: String,
        omslag: String?,
        rgsLevel: Int?,
        naturalSide: Direction?,
        dims: DimensionSlice
    ) {
        self.period = period
        self.amount = amount
        self.direction = direction
        self.rgsCode = rgsCode
        self.omslag = omslag
        self.rgsLevel = rgsLevel
        self.naturalSide = naturalSide
        self.dims = dims
    }
}
// amount: signed (DR+ / CR−) or keep (amount, direction)

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
