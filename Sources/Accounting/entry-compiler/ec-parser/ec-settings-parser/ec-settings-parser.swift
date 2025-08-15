import Foundation

public final class EntryCompilerSettingsParser: EntryCompilerParsing {
    public let core: EntryCompilerParserCore
    public init(core: EntryCompilerParserCore) { self.core = core }
    public convenience init(tokens: [EntryCompilerToken]) {
        self.init(core: EntryCompilerParserCore(tokens: tokens))
    }

    public func parseSettingsBlock() throws -> EntryCompilerSettings {
        try expectKeyword("settings")
        try beginBlock()

        var entrySettings: EntrySettings?
        var aggregationSettings: AggregationSettings?

        while current != .rBrace && current != .eof {
            switch current {
            case .keyword("entry"):
                entrySettings = try parseEntrySettings()
            case .keyword("aggregation"):
                aggregationSettings = try parseAggregationSettings()
            default:
                throw ParserError.unexpectedToken(current, expected: "entry or aggregation", at: loc())
            }
        }

        try endBlock()

        guard let es = entrySettings else {
            throw ParserError.unexpectedToken(current, expected: "entry { default_timezone = … }", at: loc())
        }
        guard let `as` = aggregationSettings else {
            throw ParserError.unexpectedToken(current, expected: "aggregation { include_previous_periods = … }", at: loc())
        }

        return EntryCompilerSettings(entry: es, aggregation: `as`)
    }

    private func parseEntrySettings() throws -> EntrySettings {
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

    private func parseAggregationSettings() throws -> AggregationSettings {
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
