import Foundation

enum EntryCompilerCLIError: LocalizedError {
    case notPorted(commandPath: [String])
    case validation(String)

    var errorDescription: String? {
        switch self {
        case .notPorted(let commandPath):
            return "ec command not ported yet: \(commandPath.joined(separator: " "))"

        case .validation(let message):
            return message
        }
    }
}
