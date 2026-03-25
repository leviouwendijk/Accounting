import Foundation

public enum EntryCompilerLexingFlavor: Sendable {
    case settings
    case accounts
    case entities
    case entries
    case transactions
    case documents

    case string
    case fallback
}
