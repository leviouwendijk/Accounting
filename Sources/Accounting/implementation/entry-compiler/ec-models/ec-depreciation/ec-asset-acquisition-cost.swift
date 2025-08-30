import Foundation

public struct AssetAcquisitionCost: Sendable, Codable {
    public let direct: Decimal
    public let indirect: Decimal
    
    public init(
        direct: Decimal,
        indirect: Decimal = 0
    ) {
        self.direct = direct
        self.indirect = indirect
    }

    public var cost: Decimal {
        return direct + indirect
    }
}
