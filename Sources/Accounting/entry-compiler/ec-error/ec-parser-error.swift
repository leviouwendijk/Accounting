import Foundation

public enum ParserError: Error, CustomStringConvertible {
    case unexpectedToken(EntryCompilerToken, expected: String, at: SourceLocation)
    case unterminatedBlock(SourceLocation)
    case deprecatedPathSegment(segment: String, suggestion: String, at: SourceLocation)

    case duplicateEntityKey(EntityKey)
    case entityNotFoundRef(String)
    case ambiguousEntityAlias(alias: String, candidates: [String])

    public var description: String {
        switch self {
        case let .unexpectedToken(tok, expected, loc):
            return "Unexpected token \(tok) at \(loc). Expected \(expected)."
        case let .unterminatedBlock(loc):
            return "Unterminated block starting at \(loc)."
        case let .deprecatedPathSegment(segment, suggestion, loc):
            return "Deprecated path segment '\(segment)' at \(loc). Use '\(suggestion)' instead (e.g., objects.inventory.o_ring → objects.storable.o_ring)."
        case let .duplicateEntityKey(key):
            return "Duplicate entity key: \(key.identifier(displaying: .fullchain)). Keys must be unique."
        case let .entityNotFoundRef(ref):
            return "Unknown entity reference: \(ref). Define it in config/entities/…"
        case let .ambiguousEntityAlias(alias, cands):
            return "Ambiguous entity alias '\(alias)'. Candidates: \(cands.joined(separator: ", ")). Qualify with class/family."
        }
    }
}
