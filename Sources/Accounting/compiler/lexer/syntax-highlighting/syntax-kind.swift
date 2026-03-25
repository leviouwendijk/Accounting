import Foundation

public enum ECSyntaxKind: String, Sendable {
    case plain
    case keyword
    case identifier
    case number
    case string
    case date
    case punctuation
}
