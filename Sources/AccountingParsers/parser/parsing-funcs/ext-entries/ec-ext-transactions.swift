import Foundation
import Accounting

public extension EntryCompilerParsing {
    @inlinable
    func parseTransactionsBlock() throws -> [Int] {
        try expect(.keyword("transactions"))
        try expect(.lBrace)

        var out: [Int] = []
        while current != .rBrace && current != .eof {
            try expect(.keyword("ref"))
            try parseRefList(into: &out)
            // newline(s) are skipped by the lexer; nothing to do here
        }
        try expect(.rBrace)

        var seen = Set<Int>()
        return out.filter { seen.insert($0).inserted }
    }

    @inlinable
    func parseRefList(into out: inout [Int]) throws {
        // first number required
        guard case let .number(n0) = current else {
            throw ParserError.unexpectedToken(current, expected: "number (transaction id)", at: loc())
        }
        out.append((n0 as NSDecimalNumber).intValue)
        advance()

        // subsequent ", <number>" pairs; allow trailing comma
        while current == .comma {
            advance()
            guard case let .number(n) = current else {
                // trailing comma before next token (e.g. next 'ref' or '}') – accept & stop
                break
            }
            out.append((n as NSDecimalNumber).intValue)
            advance()
        }
    }
}
