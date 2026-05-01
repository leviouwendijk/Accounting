import Foundation

public enum ECSyntaxKind: String, Sendable {
    case plain
    case keyword
    case identifier
    case account
    case entity
    case number
    case string
    case date
    case punctuation
    case comment
}
