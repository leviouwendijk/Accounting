import Foundation

public extension EntryCompilerParsing {
    func parseTimeZoneValue() throws -> TimeZone {
        guard case let .ident(s) = current else {
            throw ParserError.unexpectedToken(current, expected: "timezone identifier", at: loc())
        }
        // IANA
        if let tz = TimeZone(identifier: s) {
            advance()
            return tz
        }

        throw ParserError.unexpectedToken(current, expected: "IANA tz", at: loc())
    }

    func parseEntrySettings() throws -> EntrySettings {
        try expectKeyword("entry"); try beginBlock()

        var tz: TimeZone?

        while current != .rBrace && current != .eof {
            switch current {
            case .ident("default_timezone"):
                advance(); try expect(.equals)
                let parsedTZ = try parseTimeZoneValue() // supports IANA
                tz = parsedTZ
            default:
                throw ParserError.unexpectedToken(current, expected: "default_timezone", at: loc())
            }
        }

        try endBlock()
        guard let finalTZ = tz else {
            throw ParserError.unexpectedToken(current, expected: "default_timezone", at: loc())
        }
        return EntrySettings(defaultTimezone: finalTZ)
    }

    func parseAggregationSettings() throws -> AggregationSettings {
        try expectKeyword("aggregation"); try beginBlock()

        var includePrev: Bool?

        while current != .rBrace && current != .eof {
            switch current {
            case .ident("include_previous_periods"):
                advance(); try expect(.equals)
                includePrev = try parseBoolValue()
            default:
                throw ParserError.unexpectedToken(current, expected: "include_previous_periods", at: loc())
            }
        }

        try endBlock()
        guard let ip = includePrev else {
            throw ParserError.unexpectedToken(current, expected: "include_previous_periods", at: loc())
        }
        return AggregationSettings(includePreviousPeriods: ip)
    }
}
