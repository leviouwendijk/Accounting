import Foundation

public enum PeriodKind: String, Codable, Sendable {
    case year
    case quarter
    case month
    case week            // ISO-8601 week (Mon–Sun)
    case custom
    case lifetime             // no filter
}

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

public struct PeriodWindow: Sendable, Equatable {
    public let from: Date?   // nil = beginning of time
    public let to: Date?     // nil = through latest (inclusive day end)
    public init(from: Date?, to: Date?) { self.from = from; self.to = to }
}

public struct PeriodWindows: Sendable {
    /// entries with date < window.from (basis for NI overlay into equity)
    public let historical: PeriodWindow
    /// reporting slice [from ... to]
    public let window: PeriodWindow
    /// cumulative up to window.to (for BS seed)
    public let ytd: PeriodWindow
    /// contiguous, same-length previous slice (optional)
    public let previous: PeriodWindow?
}

