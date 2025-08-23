import Foundation

public enum EntityStoreError: Error, CustomStringConvertible, Sendable {
    case duplicateKey(EntityKey)
    case notFound(ref: String, at: SourceLocation? = nil)
    case ambiguousAlias(alias: String, candidates: [String], at: SourceLocation? = nil)

    public var description: String {
        switch self {
        case let .duplicateKey(key):
            return "Duplicate entity key: \(key.identifier(displaying: .fullchain)). Keys must be unique."

        case let .notFound(ref, loc):
            var s = "Unknown entity reference: \(ref). Define it in config/entities/…"
            if let loc { s += " @ \(loc)" }
            return s

        case let .ambiguousAlias(alias, cands, loc):
            var s = "Ambiguous entity alias '\(alias)'. Candidates: \(cands.joined(separator: ", ")). Qualify with class/family."
            if let loc { s += " @ \(loc)" }
            return s
        }
    }
}

public enum AccountStoreError: Error, CustomStringConvertible, Sendable {
    case duplicateCode(String)
    case notFound(code: String)
    case invalidReference(path: [String], at: SourceLocation? = nil)
    case missingRequiredForNewAccount(code: String, missing: String)

    public var description: String {
        switch self {
        case let .duplicateCode(code):
            return "Duplicate account code: \(code). Codes must be unique."
        case let .notFound(code):
            return "Unknown account code: \(code). Define it in config/accounts/… (or base RGS set)."
        case let .invalidReference(path, loc):
            var s = "Invalid account reference: \(path.joined(separator: ".")). Use a numeric code (e.g., 10201)."
            if let loc { s += " @ \(loc)" }
            return s
        case .missingRequiredForNewAccount(let code, let missing):
            return "Cannot create new account \(code): missing required \(missing)."
        }
    }
}

public enum TransactionStoreError: Error, CustomStringConvertible, Sendable {
    case duplicateID(Int)
    case notFound(id: Int, at: SourceLocation? = nil)

    public var description: String {
        switch self {
        case .duplicateID(let id):
            return "Duplicate transaction id: \(id). IDs must be unique."
        case .notFound(let id, let loc):
            var s = "Unknown transaction id: \(id). Import or define it before referencing."
            if let loc { s += " @ \(loc)" }
            return s
        }
    }
}
