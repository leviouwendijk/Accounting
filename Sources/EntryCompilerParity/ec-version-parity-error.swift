import Foundation

enum ECVersionParityError: LocalizedError {
    case missingValue(String)
    case invalidInteger(
        flag: String,
        value: String
    )
    case unknownArgument(String)

    var errorDescription: String? {
        switch self {
        case .missingValue(let flag):
            "Missing value after \(flag)."

        case .invalidInteger(let flag, let value):
            "Invalid integer for \(flag): \(value)."

        case .unknownArgument(let argument):
            "Unknown argument: \(argument)."
        }
    }
}

