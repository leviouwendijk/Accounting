import Foundation

public struct DepreciationScheduleSetting: Sendable, Codable {
    public var method: DepreciationMethod
    public var usefulLifeYears: Decimal
    public var effectiveDate: Date
    
    public init(
        method: DepreciationMethod,
        usefulLifeYears: Decimal,
        effectiveDate: Date
    ) {
        self.method = method
        self.usefulLifeYears = usefulLifeYears
        self.effectiveDate = effectiveDate
    }
}
