import Foundation
import Primitives

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

    /// The final component is the filename; the preceding three are year, quarter, month.
    public init(pathComponents: [String]) throws {
        guard pathComponents.count >= 4 else {
            throw EntryDateInferenceError.badPath(
                "need .../<year>/<quarter>/<month>/<file>.ec, got: \(pathComponents.joined(separator: "/"))"
            )
        }

        let yearString = pathComponents[pathComponents.count - 4]
        let quarterString = pathComponents[pathComponents.count - 3]
        let monthString = pathComponents[pathComponents.count - 2]
        guard let year = Int(yearString), year > 0 else {
            throw EntryDateInferenceError.badYear(yearString)
        }
        guard let quarter = Int(quarterString), (1...4).contains(quarter) else {
            throw EntryDateInferenceError.badQuarter(quarterString)
        }
        guard let month = Int(monthString), (1...12).contains(month) else {
            throw EntryDateInferenceError.badMonth(monthString)
        }
        try self.init(year: year, quarter: quarter, month: month)
    }

    public func completionContext(timezone: TimeZone) throws -> DateCompletionContext {
        try DateCompletionContext(year: year, month: month, timezone: timezone)
    }
}

/// Compatibility adapter while entry source locations are stored as Position.file.
public func inferEntrySourcePeriod(from filePath: String) throws -> EntrySourcePeriod {
    let url = URL(fileURLWithPath: filePath)
    return try EntrySourcePeriod(pathComponents: url.deletingPathExtension().pathComponents)
}

/// Compatibility tuple for existing clients; prefer EntrySourcePeriod for new code.
@inline(__always)
public func inferYearQuarterMonth(from filePath: String) throws -> (year: Int, quarter: Int, month: Int) {
    let period = try inferEntrySourcePeriod(from: filePath)
    return (period.year, period.quarter, period.month)
}
