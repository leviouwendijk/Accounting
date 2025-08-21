import Foundation

// Parsing functions for Entries
public extension EntryCompilerParsing {
    // ---- Common atoms used across parsers
    func parseAmountDirective() throws -> (Direction, Decimal) {
        guard current == .keyword("debit") || current == .keyword("credit")
           || current == .keyword("dr")    || current == .keyword("cr")
        else {
            throw ParserError.unexpectedToken(current, expected: "debit/credit/dr/cr", at: loc())
        }
        let dir: Direction = (current == .keyword("debit") || current == .keyword("dr")) ? .debit : .credit
        advance()
        try expect(.equals)
        guard case let .number(n) = current else {
            throw ParserError.unexpectedToken(current, expected: "number", at: loc())
        }
        let amt = n
        advance()
        return (dir, amt)
    }
}
