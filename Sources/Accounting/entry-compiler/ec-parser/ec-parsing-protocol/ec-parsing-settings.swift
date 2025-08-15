import Foundation

// Parser funcs for Settings
public extension EntryCompilerParsing {
    // @discardableResult
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

    // ---- Blocks
    func beginBlock() throws { try expect(.lBrace) }
    func endBlock()   throws { try expect(.rBrace)  }

    // @discardableResult
    func expectFieldEquals(_ name: String) throws -> Void {
        guard case .ident(name) = current else {
            throw ParserError.unexpectedToken(current, expected: name, at: loc())
        }
        advance()
        try expect(.equals)
    }

    // ---- Booleans: accepts true/false as ident or keyword
    func parseBoolValue() throws -> Bool {
        switch current {
        case .ident("true"), .keyword("true"):  advance(); return true
        case .ident("false"), .keyword("false"): advance(); return false
        default:
            throw ParserError.unexpectedToken(current, expected: "true|false", at: loc())
        }
    }

    // ---- TimeZone value: supports IANA ("Europe/Amsterdam") and "UTC±HH[:MM]"
    func parseTimeZoneValue() throws -> TimeZone {
        guard case let .ident(s) = current else {
            throw ParserError.unexpectedToken(current, expected: "timezone identifier", at: loc())
        }
        // Try IANA first
        if let tz = TimeZone(identifier: s) {
            advance()
            return tz
        }

        throw ParserError.unexpectedToken(current, expected: "IANA tz", at: loc())
    }
}
