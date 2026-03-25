import Foundation

// e.g. entries/2025/1/2/main.ec  -> (2025, 1 (q), 2 (m))
@inline(__always)
public func inferYearQuarterMonth(from filePath: String) throws -> (year: Int, quarter: Int, month: Int) {
    let url = URL(fileURLWithPath: filePath)
    let comps = url.deletingPathExtension().pathComponents
    guard comps.count >= 4 else {
        throw EntryDateInferenceError.badPath("need .../<year>/<quarter>/<month>/<file>.ec, got: \(filePath)")
    }
    let monthStr   = comps[comps.count - 2]
    let quarterStr = comps[comps.count - 3]
    let yearStr    = comps[comps.count - 4]

    guard let year = Int(yearStr), year > 0 else { throw EntryDateInferenceError.badYear(yearStr) }
    guard let quarter = Int(quarterStr), (1...4).contains(quarter) else { throw EntryDateInferenceError.badQuarter(quarterStr) }
    guard let month = Int(monthStr), (1...12).contains(month) else { throw EntryDateInferenceError.badMonth(monthStr) }

    return (year, quarter, month)
}
