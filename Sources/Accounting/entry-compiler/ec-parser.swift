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
            switch current {
            case .keyword("date"):
                advance()
                if current == .equals {
                advance()
                    switch current {
                    case let .number(n):
                        entry.date = Date(timeIntervalSince1970: (n as NSDecimalNumber).doubleValue)
                        advance()
                    case let .dateLiteral(text):
                        entry.date = parseDateLiteral(text)   // split on "-" or "/"
                        advance()
                    default:
                        throw ParserError.unexpectedToken(current, expected: "number or dateLiteral", at: currentLocation())
                    }
                } else if current == .lBrace {
                    // handle block-style date { year = …; month = …; day = … }
                    entry.date = try parseDateBlock()
                }

            case .keyword("details"):
                advance()                       // consume 'details'
                try expect(.lBrace)            // now expect '{'
                guard case let .string(txt) = current else {
                    throw ParserError.unexpectedToken(current, expected: "string block", at: currentLocation())
                }
                entry.details = txt
                advance()                       // consume string
                try expect(.rBrace)            // consume closing '}'

            case .keyword("for"):
                entry.lines.append(try parseLine())

            default:
                throw ParserError.unexpectedToken(
                    current,
                    expected: "date, details, or for",
                    at: currentLocation()
                )
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

    private mutating func parseDateBlock() throws -> Date {
        try expect(.lBrace)

        var comps = DateComponents()
        while current != .rBrace {
            switch current {
            case .keyword("year"):
                try expect(.keyword("year"))
                try expect(.equals)
                // extract number
                guard case let .number(n) = current else {
                    throw ParserError.unexpectedToken(current,
                        expected: "number", at: currentLocation())
                }
                comps.year = (n as NSDecimalNumber).intValue
                advance()

            case .keyword("month"):
                try expect(.keyword("month"))
                try expect(.equals)
                // extract identifier or number
                if case let .ident(s) = current {
                    let mstr = s.lowercased()
                    // map "jan"/"january"/"01"→1 etc.
                    comps.month = monthIndex(from: mstr)
                    advance()
                } else if case let .number(n) = current {
                    comps.month = (n as NSDecimalNumber).intValue
                    advance()
                } else {
                    throw ParserError.unexpectedToken(current,
                        expected: "identifier or number", at: currentLocation())
                }

            case .keyword("day"):
                try expect(.keyword("day"))
                try expect(.equals)
                guard case let .number(n) = current else {
                    throw ParserError.unexpectedToken(current,
                        expected: "number", at: currentLocation())
                }
                comps.day = (n as NSDecimalNumber).intValue
                advance()

            default:
                throw ParserError.unexpectedToken(current,
                    expected: "year, month, or day", at: currentLocation())
            }
        }

        try expect(.rBrace)
        return Calendar.current.date(from: comps) ?? Date()
    }

    private func monthIndex(from m: String) -> Int {
        let lower = m.lowercased()
        let names = Calendar.current.monthSymbols.map { $0.lowercased() }
        if let idx = names.firstIndex(of: lower) { return idx + 1 }
        let abbr = Calendar.current.shortMonthSymbols.map { $0.lowercased() }
        if let idx = abbr.firstIndex(of: lower) { return idx + 1 }
        return Int(m) ?? 1
    }

    private func parseDateLiteral(_ text: String) -> Date {
        let sep = text.contains("/") ? "/" : "-"
        let parts = text.split(separator: Character(sep)).map(String.init)
        let (y,m,d) = sep == "/" 
            ? (Int(parts[2])!, Int(parts[1])!, Int(parts[0])!)
            : (Int(parts[0])!, Int(parts[1])!, Int(parts[2])!)
        var comps = DateComponents()
        comps.year = y; comps.month = m; comps.day = d
        return Calendar.current.date(from: comps) ?? Date()
    }

    private func currentLocation() -> SourceLocation {
        return SourceLocation(line: line, column: column)
    }
}
