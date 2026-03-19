import Foundation

public enum EntryDateInferenceError: Error, LocalizedError {
    case badPath(String)
    case badYear(String)
    case badQuarter(String)
    case badMonth(String)
    case badDay(Int, Int, Int)

    public var errorDescription: String? {
        switch self {
        case .badPath(let p):   return "Entry date inference failed: invalid path structure: \(p)"
        case .badYear(let y):   return "Entry date inference failed: invalid year: \(y)"
        case .badQuarter(let q):return "Entry date inference failed: invalid quarter: \(q)"
        case .badMonth(let m):  return "Entry date inference failed: invalid month: \(m)"
        case .badDay(let y, let m, let d):
            return "Entry date inference failed: invalid day \(d) for \(y)-\(m)."
        }
    }
}
