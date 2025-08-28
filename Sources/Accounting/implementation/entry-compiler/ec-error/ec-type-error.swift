import Foundation

public enum TypeInferenceError: Error, CustomStringConvertible {
    case invalidString(string: String, type: String)

    public var description: String {
        switch self {
        case let .invalidString(string, type):
            return "Cannot initialize type \"\(type)\" with provided string: \(string)"
        }
    }
}
