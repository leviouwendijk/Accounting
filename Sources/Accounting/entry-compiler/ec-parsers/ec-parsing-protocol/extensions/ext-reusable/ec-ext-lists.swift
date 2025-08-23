import Foundation

public extension EntryCompilerParsing {
    @inlinable
    func parseIntList(into out: inout [Int]) throws {
        guard case let .number(n0) = current else {
            throw ParserError.unexpectedToken(current, expected: "number", at: loc())
        }
        out.append((n0 as NSDecimalNumber).intValue)
        advance()

        while current == .comma {
            advance()
            switch current {
            case let .number(n):
                out.append((n as NSDecimalNumber).intValue)
                advance()
            case .rBrace, .rPar, .eof:
                return
            default:
                throw ParserError.unexpectedToken(current, expected: "number or list terminator", at: loc())
            }
        }
    }
}
