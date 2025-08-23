import Foundation

public enum ParserError: Error, CustomStringConvertible {
    case unexpectedToken(EntryCompilerToken, expected: String, at: SourceLocation)
    case unterminatedBlock(SourceLocation)
    case deprecatedPathSegment(segment: String, suggestion: String, at: SourceLocation)

    public var description: String {
        switch self {
        case let .unexpectedToken(tok, expected, loc):
            return """
            unexpected token
                token: \(tok)
                expected: \(expected).
                at: \(loc) 
            """
        case let .unterminatedBlock(loc):
            return "Unterminated block starting at \(loc)."
        case let .deprecatedPathSegment(segment, suggestion, loc):
            return "Deprecated path segment '\(segment)' at \(loc). Use '\(suggestion)' instead (e.g., objects.inventory.o_ring → objects.storable.o_ring)."
        }
    }
}
