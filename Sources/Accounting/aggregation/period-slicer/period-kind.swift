import Foundation
import Primitives
import Arguments

public enum PeriodKind: String, Codable, Sendable, StringParsableEnum, ArgumentValue {
    case year
    case half // half year
    case quarter
    case month
    case week            // ISO-8601 week (Mon–Sun)
    case custom
    case lifetime             // no filter
}

extension PeriodKind {
    public var previousPeriodLabel: String {
        switch self {
        case .year:
            return "vorig jaar"

        case .half:
            return "vorig halfjaar"

        case .quarter:
            return "vorig kwartaal"

        case .month:
            return "vorige maand"

        case .week:
            return "vorige week"

        case .custom, .lifetime:
            return "vorige periode"
        }
    }
}
