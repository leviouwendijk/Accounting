import Foundation

public enum PeriodKind: String, Codable, Sendable {
    case year
    case half // half year
    case quarter
    case month
    case week            // ISO-8601 week (Mon–Sun)
    case custom
    case lifetime             // no filter
}
