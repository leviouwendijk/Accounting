import Foundation
import Primitives
import Path

/// Validated directory period for entries stored in year/quarter/month folders.
/// Independent of any filesystem representation; callers may supply native Path segments.
public struct EntrySourcePeriod: Hashable, Sendable {
    public let year: Int
    public let quarter: Int
    public let month: Int

    public init(year: Int, quarter: Int, month: Int) throws {
        guard year > 0 else { throw EntryDateInferenceError.badYear(String(year)) }
        guard (1...4).contains(quarter) else {
            throw EntryDateInferenceError.badQuarter(String(quarter))
        }
        guard (1...12).contains(month) else {
            throw EntryDateInferenceError.badMonth(String(month))
        }
        guard quarter == ((month - 1) / 3) + 1 else {
            throw EntryDateInferenceError.quarterMonthMismatch(quarter: quarter, month: month)
        }
        self.year = year
        self.quarter = quarter
        self.month = month
    }

    /// Compatibility for clients supplying an array with a final stem or .ec filename.
    /// The actual year/quarter/month extraction belongs to EntrySourcePath.
    public init(pathComponents: [String]) throws {
        guard pathComponents.count >= 4, let last = pathComponents.last else {
            throw EntryDateInferenceError.badPath(pathComponents.joined(separator: "/"))
        }
        guard pathComponents.allSatisfy({
            !$0.isEmpty && $0 != "." && $0 != ".." && !$0.contains("/")
        }) else {
            throw EntryDateInferenceError.badPath(pathComponents.joined(separator: "/"))
        }
        let canonical = Array(pathComponents.dropLast()) + [
            last.hasSuffix(".ec") ? last : last + ".ec"
        ]
        self = try EntrySourcePath.period(from: StandardPath(canonical))
    }

    public func completionContext(timezone: TimeZone) throws -> DateCompletionContext {
        try DateCompletionContext(year: year, month: month, timezone: timezone)
    }
}

/// Compatibility adapter while entry source locations are stored as Position.file.
public func inferEntrySourcePeriod(from filePath: String) throws -> EntrySourcePeriod {
    try EntrySourcePath.period(from: StandardPath(rawPath: filePath))
}

/// Compatibility tuple for existing clients; prefer EntrySourcePeriod for new code.
@inline(__always)
public func inferYearQuarterMonth(from filePath: String) throws -> (year: Int, quarter: Int, month: Int) {
    let period = try inferEntrySourcePeriod(from: filePath)
    return (period.year, period.quarter, period.month)
}
