import Foundation

public extension EntryCompilerParsing {
    @inline(__always) var current: EntryCompilerToken { core.current }
    @inline(__always) func advance() { var c = core; c.advance(); core = c }
    @inline(__always) func expect(_ t: EntryCompilerToken) throws { var c = core; try c.expect(t); core = c }
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

    func expectFieldEquals(_ name: String) throws {
        switch current {
        case .ident(name), .keyword(name):
            advance()
        default:
            throw ParserError.unexpectedToken(current, expected: name, at: loc())
        }
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

    @discardableResult
    func expectNameOrNumberValue() throws -> String {
        switch current {
        case let .ident(s):   advance(); return s
        case let .keyword(s): advance(); return s
        case let .number(n):  advance(); return "\(n)"
        default:
            throw ParserError.unexpectedToken(current, expected: "identifier|number", at: loc())
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
