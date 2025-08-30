import Foundation

public extension EntryCompilerParsing {
    func parseEntry(defaultTimeZone: TimeZone) throws -> Entry {
        try expect(.keyword("entry"))
        try expect(.lBrace)

        var entry = Entry()
        var tz = defaultTimeZone
        entry.location = loc()

        while current != .rBrace && current != .eof {
            switch current {

            case .keyword("id"):
                try parseId(into: &entry.id)

            case .keyword("timezone"):
                advance()
                try expect(.lBrace)
                let parsed = try parseTimeZoneValue()
                try expect(.rBrace)
                tz = parsed
                entry.timezone = parsed.identifier

            case .keyword("date"):
                entry.date = try parseDateOrInfer(tz: tz, allowUnixEpoch: true)

            case .keyword("sort"):
                if entry.sort != nil {
                    throw ParserError.unexpectedToken(current, expected: "single sort directive", at: loc())
                }
                entry.sort = try parseEntrySort()

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

            case .keyword("metadata"):
                let m = try parseStringMapBlock(named: "metadata") // consumes 'metadata' and the block
                // merge (allow multiple blocks; last write wins per key)
                if entry.metadata.isEmpty { entry.metadata = m }
                else { for (k, v) in m { entry.metadata[k] = v } }

            default:
                throw ParserError.unexpectedToken(current, expected: "date, details, for, posting, or line", at: loc())
            }
        }

        try expect(.rBrace)
        return entry
    }
}
