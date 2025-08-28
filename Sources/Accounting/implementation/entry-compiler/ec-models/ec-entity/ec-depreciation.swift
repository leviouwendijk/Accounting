import Foundation

public enum DepreciationMethod: String, Codable, Sendable { 
    case straight_line, sl
    case double_declining_balance, ddb
    case sum_of_year_digits, syd
    case units_of_production, uop
}

public struct DepreciationConfig: Sendable, Codable {
    public var method: DepreciationMethod?
    public var usefulLifeYears: Decimal?
    public var residualValuePercent: Decimal
    public var residualValueAmount: Decimal?
    public var effectiveDate: Date?
    
    public init(
        method: DepreciationMethod?,
        usefulLifeYears: Decimal?,
        residualValuePercent: Decimal,   
        residualValueAmount: Decimal?,
        effectiveDate: Date?
    ) {
        self.method = method
        self.usefulLifeYears = usefulLifeYears
        self.residualValuePercent = residualValuePercent
        self.residualValueAmount = residualValueAmount
        self.effectiveDate = effectiveDate
    }
}
