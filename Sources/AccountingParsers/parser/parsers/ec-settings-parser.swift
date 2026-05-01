import Foundation
import Accounting
import Position

public final class EntryCompilerSettingsParser: EntryCompilerParsing {
    public var core: EntryCompilerParserCore
    private let fileURL: URL?

    public init(core: EntryCompilerParserCore, fileURL: URL? = nil) {
        self.core = core
        self.fileURL = fileURL
    }

    public convenience init(
        tokens: [EntryCompilerToken],
        fileURL: URL? = nil,
        lineMap: [Int]? = nil,
        spanMap: [PositionSpan]? = nil,
        verbose: Bool = false
    ) {
        self.init(
            core: .init(
                tokens: tokens,
                filePath: fileURL?.path,
                lineMap: lineMap,
                spanMap: spanMap,
                verbose: verbose
            ),
            fileURL: fileURL
        )
    }

    public func parseSettingsBlock() throws -> EntryCompilerSettings {
        core.trace("parsing settings file: \(fileURL?.lastPathComponent ?? "<memory>")")
        try expectKeyword("settings")
        try beginBlock()

        var entrySettings: EntrySettings?
        var aggregationSettings: AggregationSettings?
        var statementDataSettings: StatementDataSettings?

        while current != .rBrace && current != .eof {
            switch current {
            case .keyword("entry"):
                core.trace("• settings entry block @ \(loc())")
                entrySettings = try parseEntrySettings()

            case .keyword("aggregation"):
                core.trace("• settings aggregation block @ \(loc())")
                aggregationSettings = try parseAggregationSettings()

            case .keyword("statement_data"), .ident("statement_data"):
                core.trace("• settings statement_data block @ \(loc())")
                statementDataSettings = try parseStatementDataSettings()

            default:
                throw ParserError.unexpectedToken(current, expected: "entry or aggregation", at: loc())
            }
        }

        try endBlock()

        guard let es = entrySettings else {
            throw ParserError.unexpectedToken(current, expected: "entry { default_timezone = … }", at: loc())
        }
        core.trace("  → \(es.defaultTimezone)")

        guard let `as` = aggregationSettings else {
            throw ParserError.unexpectedToken(current, expected: "aggregation { include_previous_periods = … }", at: loc())
        }
        core.trace("  → \(`as`.includePreviousPeriods)")

        return EntryCompilerSettings(
            entry: es,
            aggregation: `as`,
            statementData: statementDataSettings
        )
    }
}
