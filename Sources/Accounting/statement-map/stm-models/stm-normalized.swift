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
