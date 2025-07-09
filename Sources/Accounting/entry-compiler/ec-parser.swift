import Foundation

public enum ParserError: Error, CustomStringConvertible {
    case unexpectedToken(EntryCompilerToken, expected: String, at: SourceLocation)
    case unterminatedBlock(SourceLocation)

    public var description: String {
        switch self {
        case let .unexpectedToken(tok, expected, loc):
            return "Unexpected token \(tok) at \(loc). Expected \(expected)."
        case let .unterminatedBlock(loc):
            return "Unterminated block starting at \(loc)."
        }
    }
}

public struct EntryCompilerParser {
    private let tokens: [EntryCompilerToken]
    private var index = 0
    private var line = 1, column = 1

    public init(tokens: [EntryCompilerToken]) {
        self.tokens = tokens
    }

    private var current: EntryCompilerToken {
        return index < tokens.count ? tokens[index] : .eof
    }

    private mutating func advance() {
        index += 1
        column += 1
    }

    private mutating func expect(_ expected: EntryCompilerToken) throws {
        guard current == expected else {
            throw ParserError.unexpectedToken(current, expected: "\(expected)", at: .init(line: line, column: column))
        }
        advance()
    }

    public mutating func parseEntries() throws -> [Entry] {
        var entries: [Entry] = []
        while current != .eof {
            entries.append(try parseEntry())
        }
        return entries
    }

    private mutating func parseEntry() throws -> Entry {
        try expect(.keyword("entry"))
        try expect(.lBrace)
        var entry = Entry()
        while current != .rBrace && current != .eof {
            if case .keyword("date") = current {
                advance() // keyword
                try expect(.equals)
                if case let .number(val) = current {
                    entry.date = Date(timeIntervalSince1970: (val as NSDecimalNumber).doubleValue)
                    advance()
                }
            }
            else if case .keyword("details") = current {
                advance()
                if case let .string(txt) = current {
                    entry.details = txt
                    advance()
                }
            }
            else if case .keyword("for") = current {
                entry.lines.append(try parseLine())
            }
            else {
                throw ParserError.unexpectedToken(current, expected: "date, details, or for", at: .init(line: line, column: column))
            }
        }
        try expect(.rBrace)
        return entry
    }

    private mutating func parseLine() throws -> Line {
        advance()                      // consume 'for'
        let entity = try parseEntityPath()
        try expect(.keyword("in"))
        let account = try parseAccountPath()
        try expect(.lBrace)

        var direction: Direction = .debit
        var amount: Decimal = 0

        if case .keyword("debit") = current {
            direction = .debit
            advance()
        } else if case .keyword("credit") = current {
            direction = .credit
            advance()
        } else if case .keyword("rm") = current {
            direction = .credit // or custom enum
            advance()
        } else {
            throw ParserError.unexpectedToken(current, expected: "debit, credit, or rm", at: .init(line: line, column: column))
        }

        try expect(.equals)
        if case let .number(val) = current {
            amount = val
            advance()
        } else {
            throw ParserError.unexpectedToken(current, expected: "number", at: .init(line: line, column: column))
        }

        try expect(.rBrace)
        return Line(entity: entity, account: account, direction: direction, amount: amount)
    }

    private mutating func parseEntityPath() throws -> EntityPath {
        // entity(people->levi_ouwendijk)
        guard case .ident("entity") = current else {
            throw ParserError.unexpectedToken(current, expected: "entity", at: .init(line: line, column: column))
        }
        advance()
        try expect(.lPar)
        // collect segments until ')'
        var segments: [String] = []
        while current != .rPar && current != .eof {
            if case let .ident(s) = current {
                segments.append(s)
            }
            advance()
            if current == .arrow || current == .dot {
                advance()
            }
        }
        try expect(.rPar)
        guard segments.count >= 2 else {
            throw ParserError.unexpectedToken(current, expected: "domain.alias", at: .init(line: line, column: column))
        }
        let domain = segments.first!
        let alias = Array(segments.dropFirst())
        return EntityPath(domain: domain, aliasSegments: alias)
    }

    private mutating func parseAccountPath() throws -> AccountPath {
        // account(assets.cash.bank_balances)
        guard case .ident("account") = current else {
            throw ParserError.unexpectedToken(current, expected: "account", at: .init(line: line, column: column))
        }
        advance()
        try expect(.lPar)
        var segments: [String] = []
        while current != .rPar && current != .eof {
            if case let .ident(s) = current {
                segments.append(s)
            }
            advance()
            if current == .dot || current == .arrow {
                advance()
            }
        }
        try expect(.rPar)
        return AccountPath(segments: segments)
    }
}
