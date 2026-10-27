import Foundation
import Accounting

public extension EntryCompilerParsing {
    func parseEntry(defaultTimeZone: TimeZone) throws -> Entry {
        try expect(.keyword("entry"))
        try expect(.lBrace)

        // A parsed Entry always has a date. Only the parser's intermediate state may lack one.
        let location = loc()
        var id: Int?
        var date: DateSpecification?
        var history: EntryHistory?
        var sort: EntrySort?
        var lines: [Line] = []
        var details: String?
        var timezone: String?
        var transactionReferences: [Int] = []
        var vat: VATAnnotation?
        var metadata: [String: String] = [:]
        var mistake: Mistake?
        var select: EntrySelect?
        var tz = defaultTimeZone

        while current != .rBrace && current != .eof {
            switch current {
            case .keyword("id"):
                try parseId(into: &id)

            case .keyword("timezone"):
                advance()
                try expect(.lBrace)
                let parsed = try parseTimeZoneValue()
                try expect(.rBrace)
                tz = parsed
                timezone = parsed.identifier

            case .keyword("date"):
                guard date == nil else {
                    throw ParserError.unexpectedToken(
                        current, expected: "single date directive", at: loc()
                    )
                }
                date = try parseDateOrInfer(tz: tz, allowUnixEpoch: true)

            case .keyword("history"):
                guard history == nil else {
                    throw ParserError.unexpectedToken(
                        current, expected: "single history block", at: loc()
                    )
                }
                history = try parseHistoryBlock(tz: tz)

            case .keyword("sort"):
                guard sort == nil else {
                    throw ParserError.unexpectedToken(
                        current, expected: "single sort directive", at: loc()
                    )
                }
                sort = try parseEntrySort()

            case .keyword("details"):
                advance()
                try expect(.lBrace)
                guard case let .string(txt) = current else {
                    throw ParserError.unexpectedToken(current, expected: "string block", at: loc())
                }
                details = txt
                advance()
                try expect(.rBrace)

            case .keyword("for"), .keyword("in"):
                lines.append(contentsOf: try parseMultiLinesOrSwap())

            case .keyword("posting"), .keyword("line"):
                lines.append(try parsePostingBlock())

            case .keyword("transactions"):
                transactionReferences.append(contentsOf: try parseTransactionsBlock())

            case .keyword("vat"), .ident("vat"):
                guard vat == nil else {
                    throw ParserError.unexpectedToken(
                        current, expected: "single vat block", at: loc()
                    )
                }
                vat = try parseVATBlock()

            case .keyword("metadata"):
                let m = try parseStringMapBlock(named: "metadata")
                for (key, value) in m { metadata[key] = value }

            case .keyword("mistake"):
                mistake = try parseMistakeBlock()

            case .keyword("select"):
                select = try parseSelectBlock()

            default:
                throw ParserError.unexpectedToken(
                    current,
                    expected: "id|timezone|date|history|sort|details|for|in|posting|line|transactions|vat|metadata|mistake|select",
                    at: loc()
                )
            }
        }

        try expect(.rBrace)
        guard let date else {
            throw ParserError.unexpectedToken(
                current, expected: "date directive in entry", at: location
            )
        }
        return Entry(
            id: id,
            date: date,
            history: history,
            sort: sort,
            lines: lines,
            details: details,
            timezone: timezone,
            transactionReferences: transactionReferences,
            vat: vat,
            metadata: metadata,
            location: location,
            mistake: mistake,
            select: select
        )
    }
}
