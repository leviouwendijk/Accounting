import Foundation

public struct PeriodShape: Codable, Sendable {
    public let kind: PeriodKind
    public let rangeToDate: Bool
    
    public init(
        kind: PeriodKind,
        rangeToDate: Bool = false
    ) {
        self.kind = kind
        self.rangeToDate = rangeToDate
    }
}
