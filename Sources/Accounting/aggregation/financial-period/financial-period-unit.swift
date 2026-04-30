import Foundation
import Arguments

public enum FinancialPeriodUnit: String, Sendable, Codable, CaseIterable, ArgumentValue {
    case day
    case week
    case month
    case quarter
    case half
    case year

    public var label: String {
        switch self {
        case .day:
            return "day"

        case .week:
            return "week"

        case .month:
            return "month"

        case .quarter:
            return "quarter"

        case .half:
            return "halfyear"

        case .year:
            return "year"
        }
    }

    public static let displayOrderDescending: [FinancialPeriodUnit] = [
        .year,
        .half,
        .quarter,
        .month,
        .week,
        .day,
    ]
}
