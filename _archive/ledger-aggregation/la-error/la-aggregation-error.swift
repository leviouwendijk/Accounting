import Foundation

public enum AggregationError: Error, CustomStringConvertible, Sendable {
    case unknownAccountCode(String)

    public var description: String {
        switch self {
        case .unknownAccountCode(let c): 
            return "Unknown account code \(c)."
        }
    }
}
