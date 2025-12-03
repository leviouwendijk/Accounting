import Foundation

public enum EntryCompilerLexingSetsCache {
    public static let settings     = aggregateLexingSets(flavor: .settings)
    public static let accounts     = aggregateLexingSets(flavor: .accounts)
    public static let entities     = aggregateLexingSets(flavor: .entities)
    public static let entries      = aggregateLexingSets(flavor: .entries)
    public static let transactions = aggregateLexingSets(flavor: .transactions)
    public static let string       = aggregateLexingSets(flavor: .string)
    public static let fallback     = aggregateLexingSets(flavor: .fallback)

    public static func pointer(for flavor: EntryCompilerLexingFlavor) -> EntryCompilerLexingSets {
        switch flavor {
        case .settings:     return Self.settings
        case .accounts:     return Self.accounts
        case .entities:     return Self.entities
        case .entries:      return Self.entries
        case .transactions: return Self.transactions
        case .string:       return Self.string
        case .fallback:     return Self.fallback
        }
    }
}
