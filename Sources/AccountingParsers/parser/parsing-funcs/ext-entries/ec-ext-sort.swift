import Foundation
import Accounting

public extension EntryCompilerParsing {
    @inline(__always)
    func parseEntrySort() throws -> EntrySort {
        try expect(.keyword("sort"))

        let raw: String
        switch current {
        case let .ident(s):
            raw = s; advance()
        case let .keyword(s):
            raw = s; advance()
        default:
            throw ParserError.unexpectedToken(current, expected: "regular|adjusting", at: loc())
        }

        do {
            return try EntrySort.parse(from: raw)
        } catch {
            throw ParserError.unexpectedToken(.ident(raw), expected: "regular|adjusting", at: loc())
        }
    }
}
