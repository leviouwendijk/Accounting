import Foundation

public struct EntryCompilerParserCore: Sendable {
    internal var tokens: [EntryCompilerToken]
    internal var index = 0
    internal var line = 1, column = 1

    internal var filePath: String?
    internal var callSiteStack: [InvocationCallSite] = []

    public init(tokens: [EntryCompilerToken], filePath: String? = nil) {
        self.tokens = tokens
        self.filePath = filePath
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
        SourceLocation(file: filePath, line: line, column: column, invocation: callSiteStack.last)
    }

    public mutating func pushCallSite(_ site: InvocationCallSite) {
        callSiteStack.append(site)
    }
    public mutating func popCallSite() {
        _ = callSiteStack.popLast()
    }
}

