import Foundation

public enum WinstSource: CustomStringConvertible {
    case postedAOW
    case slices(asOf: Date)
    public var description: String {
        switch self {
        case .postedAOW: return "posted AOW"
        case .slices(let d):
            let df = DateFormatter(); df.locale = Locale(identifier: "nl_NL"); df.dateFormat = "yyyy-MM-dd"
            return "ownership % slices as of \(df.string(from: d))"
        }
    }
}
