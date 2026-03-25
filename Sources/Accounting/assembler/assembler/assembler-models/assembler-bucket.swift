import Foundation

public struct L2Buckets: Sendable {
    public let assets: [Int]        // debit-oriented L2 ids
    public let equity: Int?         // the one L2 equity anchor (e.g. BEiv)
    public let liabilities: [Int]   // credit-oriented L2 ids excluding equity
}

public enum L2BucketError: LocalizedError, Sendable {
    case equityAnchorNotFound(code: String)
    case equityAnchorWrongLevel(code: String, got: UInt8)
    case equityAnchorWrongDirection(code: String, got: Direction?)

    public var errorDescription: String? {
        switch self {
        case .equityAnchorNotFound(let c):            return "L2 bucketing: equity anchor '\(c)' not found."
        case .equityAnchorWrongLevel(let c, let lvl): return "L2 bucketing: equity anchor '\(c)' is not level 2 (got level \(lvl))."
        case .equityAnchorWrongDirection(let c, let d):
            return "L2 bucketing: equity anchor '\(c)' is not credit-oriented (got \(String(describing: d)))."
        }
    }
}

