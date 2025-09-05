import Foundation

public struct PeriodWindow: Sendable, Equatable {
    public let from: Date?   // nil = beginning of time
    public let to: Date?     // nil = through latest (inclusive day end)

    public init(from: Date?, to: Date?) { self.from = from; self.to = to }

    public func string() -> String {
        let df = DateFormatter(); df.dateStyle = .medium; df.timeStyle = .none
        let fromStr = from.map { df.string(from: $0) } ?? "beginning"
        let toStr   = to.map   { df.string(from: $0) } ?? "latest"
        return "Period: \(fromStr) → \(toStr)"
    }

    public func filenameSlug(timeZone: TimeZone = .current) -> String {
        let df = DateFormatter()
        df.timeZone = timeZone
        df.dateFormat = "yyyy-MM-dd"
        let fromStr = from.map { df.string(from: $0) } ?? "beginning"
        let toStr   = to.map   { df.string(from: $0) } ?? "latest"
        return "\(fromStr)_to_\((toStr))"
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: ":", with: "-")
            .replacingOccurrences(of: "/", with: "-")
    }
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

