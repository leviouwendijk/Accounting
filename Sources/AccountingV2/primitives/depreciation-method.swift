import Foundation

public enum DepreciationMethod: String, Codable, Sendable { 
    case straight_line, sl
    case double_declining_balance, ddb
    case sum_of_year_digits, syd
    case units_of_production, uop

    public var canonical: DepreciationMethod {
        switch self {
        case .straight_line, .sl: return .straight_line
        case .double_declining_balance, .ddb: return .double_declining_balance
        case .sum_of_year_digits, .syd: return .sum_of_year_digits
        case .units_of_production, .uop: return .units_of_production
        }
    }
}
