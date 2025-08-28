import Foundation

public enum AutoCloseError: LocalizedError {
    case codeNotFound(String)
    case kindMismatch(expected: StatementKind, actual: StatementKind, code: String)

    public var errorDescription: String? {
        switch self {
        case .codeNotFound(let c):
            return "AutoClose: RGS code not found in index: \(c)"
        case .kindMismatch(let expected, let actual, let code):
            return "AutoClose: node kind mismatch for \(code) (expected \(expected), got \(actual))"
        }
    }
}
