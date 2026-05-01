import Foundation
import Accounting

public extension EntryCompilerParsing {
    @inlinable
    func parseHistoryBlock(
        tz: TimeZone
    ) throws -> EntryHistory {
        try expect(.keyword("history"))
        try beginBlock()

        var events: [EntryHistoryEvent] = []

        while current != .rBrace && current != .eof {
            switch current {
            case .keyword("recorded"), .ident("recorded"),
                 .keyword("corrected"), .ident("corrected"),
                 .keyword("adjusted"), .ident("adjusted"):
                events.append(
                    try parseHistoryEventBlock(tz: tz)
                )

            default:
                throw ParserError.unexpectedToken(
                    current,
                    expected: "recorded|corrected|adjusted|}",
                    at: loc()
                )
            }
        }

        try endBlock()
        return EntryHistory(events: events)
    }

    // @inlinable
    func parseHistoryEventBlock(
        tz: TimeZone
    ) throws -> EntryHistoryEvent {
        let eventLocation = loc()

        let rawKind: String
        switch current {
        case let .keyword(s), let .ident(s):
            rawKind = s
            advance()

        default:
            throw ParserError.unexpectedToken(
                current,
                expected: "recorded|corrected|adjusted",
                at: loc()
            )
        }

        let kind: EntryHistoryEventKind
        do {
            kind = try EntryHistoryEventKind.parse(from: rawKind)
        } catch {
            throw ParserError.unexpectedToken(
                .ident(rawKind),
                expected: "recorded|corrected|adjusted",
                at: eventLocation
            )
        }

        try beginBlock()

        var date: DateSpecification?
        var details: String?

        while current != .rBrace && current != .eof {
            switch current {
            case .keyword("date"), .ident("date"):
                if date != nil {
                    throw ParserError.unexpectedToken(
                        current,
                        expected: "single date directive",
                        at: loc()
                    )
                }

                date = try parseDateOrInfer(
                    tz: tz,
                    allowUnixEpoch: true
                )

            case .keyword("details"), .ident("details"):
                if details != nil {
                    throw ParserError.unexpectedToken(
                        current,
                        expected: "single details block",
                        at: loc()
                    )
                }

                details = try parseFreeTextBlock(named: "details")

            default:
                throw ParserError.unexpectedToken(
                    current,
                    expected: "date|details|}",
                    at: loc()
                )
            }
        }

        try endBlock()

        guard let date else {
            throw ParserError.unexpectedToken(
                current,
                expected: "date",
                at: eventLocation
            )
        }

        return EntryHistoryEvent(
            kind: kind,
            date: date,
            details: details,
            location: eventLocation
        )
    }
}
