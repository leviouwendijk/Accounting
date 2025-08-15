import Foundation

// public class EntryCompilerParserCore: Sendable {
public struct EntryCompilerParserCore: Sendable {
    internal var tokens: [EntryCompilerToken]
    internal var index = 0
    internal var line = 1, column = 1

    public init(tokens: [EntryCompilerToken]) {
        self.tokens = tokens
    }

    public var current: EntryCompilerToken { 
        index < tokens.count ? tokens[index] : .eof 
    }

    public mutating func advance() {
        index += 1; column += 1 
    }

    public mutating func expect(_ expected: EntryCompilerToken) throws {
        guard current == expected else {
            throw ParserError.unexpectedToken(
                current,
                expected: "\(expected)",
                at: currentLocation()
            )
        }
        advance()
    }

    public func currentLocation() -> SourceLocation {
        SourceLocation(line: line, column: column)
    }
}

