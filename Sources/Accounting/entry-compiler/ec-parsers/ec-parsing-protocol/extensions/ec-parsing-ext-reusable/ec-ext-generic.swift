import Foundation

public extension EntryCompilerParsing {
    @inline(__always) var current: EntryCompilerToken { core.current }
    @inline(__always) func advance() { core.advance() }
    @inline(__always) func expect(_ t: EntryCompilerToken) throws { try core.expect(t) }
    @inline(__always) func loc() -> SourceLocation { core.currentLocation() }

    func beginBlock() throws { try expect(.lBrace) }
    func endBlock()   throws { try expect(.rBrace)  }
}

public extension EntryCompilerParsing {
    func expectKeyword(_ kw: String) throws -> Void {
        guard case .keyword(kw) = current else {
            throw ParserError.unexpectedToken(current, expected: "keyword(\(kw))", at: loc())
        }
        advance()
    }

    @discardableResult
    func expectIdentValue() throws -> String {
        guard case let .ident(s) = current else {
            throw ParserError.unexpectedToken(current, expected: "identifier", at: loc())
        }
        advance()
        return s
    }

    func expectFieldEquals(_ name: String) throws -> Void {
        guard case .ident(name) = current else {
            throw ParserError.unexpectedToken(current, expected: name, at: loc())
        }
        advance()
        try expect(.equals)
    }

    func parseBoolValue() throws -> Bool {
        switch current {
        case .ident("true"), .keyword("true"):  advance(); return true
        case .ident("false"), .keyword("false"): advance(); return false
        default:
            throw ParserError.unexpectedToken(current, expected: "true|false", at: loc())
        }
    }

}


public extension EntryCompilerParsing {
    // lookahead helper
    func peekTokenIsLPar() -> Bool {
        let saved = core.index
        defer { core.index = saved }
        if saved < core.tokens.count - 1 {
            return core.tokens[saved + 1] == .lPar
        }
        return false
    }
}
