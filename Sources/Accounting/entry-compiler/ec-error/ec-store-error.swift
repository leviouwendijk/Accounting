import Foundation

public enum EntityStoreError: Error, CustomStringConvertible, Sendable {
    case duplicateKey(EntityKey)
    case notFound(ref: String)                          // printable ref (may be alias-only)
    case ambiguousAlias(alias: String, candidates: [String])

    public var description: String {
        switch self {
        case let .duplicateKey(key):
            return "Duplicate entity key: \(key.identifier(displaying: .fullchain)). Keys must be unique."
        case let .notFound(ref):
            return "Unknown entity reference: \(ref). Define it in config/entities/…"
        case let .ambiguousAlias(alias, cands):
            return "Ambiguous entity alias '\(alias)'. Candidates: \(cands.joined(separator: ", ")). Qualify with class/family."
        }
    }
}

public enum AccountStoreError: Error, CustomStringConvertible, Sendable {
    case duplicateCode(String)                          // when building the store
    case notFound(code: String)                         // strict code-based resolution
    case invalidReference(path: [String])               // non-code / unsupported path

    public var description: String {
        switch self {
        case let .duplicateCode(code):
            return "Duplicate account code: \(code). Codes must be unique."
        case let .notFound(code):
            return "Unknown account code: \(code). Define it in config/accounts/… (or base RGS set)."
        case let .invalidReference(path):
            return "Invalid account reference: \(path.joined(separator: ".")). Use a numeric code (e.g., 10201)."
        }
    }
}
