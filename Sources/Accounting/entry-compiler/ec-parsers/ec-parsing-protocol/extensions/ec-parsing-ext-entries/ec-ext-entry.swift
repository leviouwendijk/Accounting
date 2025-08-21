import Foundation

public extension EntryCompilerParsing {
    func parseEntry(defaultTimeZone: TimeZone) throws -> Entry {
        try expect(.keyword("entry"))
        try expect(.lBrace)

        var entry = Entry()
        var tz = defaultTimeZone

        while current != .rBrace && current != .eof {
            switch current {

            case .keyword("id"), .ident("id"):
                try parseId(into: &entry.id)

            case .keyword("timezone"):
                advance()
                try expect(.lBrace)
                let parsed = try parseTimeZoneValue()
                try expect(.rBrace)
                tz = parsed
                entry.timezone = parsed.identifier

            case .keyword("date"):
                advance()
                if case .keyword("infer") = current {
                    advance()
                    guard case let .number(n) = current else {
                        throw ParserError.unexpectedToken(current, expected: "number (day of month)", at: loc())
                    }
                    entry.date = .infer(day: (n as NSDecimalNumber).intValue)
                    advance()

                } else if current == .equals {
                    advance()
                    switch current {
                    case let .number(n):
                        entry.date = .absolute(Date(timeIntervalSince1970: (n as NSDecimalNumber).doubleValue)); advance()
                    case let .dateLiteral(text):
                        entry.date = .absolute(try parseDateLiteral(text, in: tz)); advance()
                    default:
                        throw ParserError.unexpectedToken(current, expected: "number or dateLiteral", at: loc())
                    }

                } else if current == .lBrace {
                    entry.date = .absolute(try parseDateBlock(tz: tz))
                } else {
                    throw ParserError.unexpectedToken(current, expected: "infer, '=', or '{'", at: loc())
                }

            case .keyword("details"):
                advance()
                try expect(.lBrace)
                guard case let .string(txt) = current else {
                    throw ParserError.unexpectedToken(current, expected: "string block", at: loc())
                }
                entry.details = txt
                advance()
                try expect(.rBrace)

            case .keyword("for"), .keyword("in"):
                entry.lines.append(
                    contentsOf: try parseMultiLinesOrSwap()
                )

            case .keyword("posting"), .keyword("line"):
                entry.lines.append(
                    try parsePostingBlock()
                )

            case .keyword("transactions"):
                let refs = try parseTransactionsBlock()
                entry.transactionReferences.append(contentsOf: refs)

            default:
                throw ParserError.unexpectedToken(current, expected: "date, details, for, posting, or line", at: loc())
            }
        }

        try expect(.rBrace)
        return entry
    }
}
