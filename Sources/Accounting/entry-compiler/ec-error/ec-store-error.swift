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
    case duplicateCode(String, at: SourceLocation?)
    case notFound(code: String, at: SourceLocation?)
    case invalidReference(path: [String], at: SourceLocation?)
    case missingRequiredForNewAccount(code: String, missing: String, at: SourceLocation?)
    case empty(at: SourceLocation?)
    case compiledChartIndexEmpty
    case hierarchyIssue(problem: RGSIdentifierHierarchy.Problem, at: SourceLocation?)

    public var description: String {
        switch self {
        case let .duplicateCode(code, at):
            return "Duplicate account code '\(code)'\(at.describeSuffix)"
        case let .notFound(code, at):
            return "Unknown account code '\(code)'\(at.describeSuffix)"
        case let .invalidReference(path, at):
            return "Invalid account reference '\(path.joined(separator: "."))'\(at.describeSuffix)"
        case let .missingRequiredForNewAccount(code, missing, at):
            return "Cannot create new account '\(code)': missing \(missing)\(at.describeSuffix)"
        case let .empty(at):
            return "Store is empty \(at.describeSuffix)"
        case .compiledChartIndexEmpty:
            return "Account Store has a CompiledChart with an empty index"
        case let .hierarchyIssue(problem, at):
            var s = "Invalid RGS hierarchy for '\(problem.childCode)' (level \(problem.childLevel)): \(problem)"
            if let at { s += at.description }
            s += " — Parent must be a proper code prefix and exactly one level above."
            return s
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
