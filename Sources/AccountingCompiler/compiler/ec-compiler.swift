import Accounting
import AccountingParsers
import Foundation
import Position

public struct EntryCompiler: Sendable {
    public let project: EntryCompilerProject
    public let parsers: EntryCompilerParsers
    public let settings: EntryCompilerSettings
    public let entities: EntityStore

    public init(root: URL, parsers: EntryCompilerParsers = .default) throws {
        self.project = .init(root: root)
        self.parsers = parsers
        self.settings = try parsers.makeSettings(root)
        self.entities = try EntityStoreLoader.load(
            from: self.project,
            settings: settings,
            verbose: false
        )
    }

    public func lex(
        _ source: String
    ) -> [EntryCompilerToken] {
        lexDetailed(source).tokens
    }

    public func lexDetailed(
        _ source: String,
        flavor: EntryCompilerLexingFlavor = .fallback
    ) -> EntryCompilerLexResult {
        var lx = EntryCompilerLexer(source: source, flavor: flavor)
        return lx.collectLexResult()
    }

    public func lexWithLineMap(
        _ source: String
    ) -> ([EntryCompilerToken], [Int]) {
        let result = lexDetailed(source)
        return (result.tokens, result.lineMap)
    }

    public func lexWithSpanMap(
        _ source: String,
        flavor: EntryCompilerLexingFlavor = .fallback
    ) -> ([EntryCompilerToken], [PositionSpan]) {
        let result = lexDetailed(source, flavor: flavor)
        return (result.tokens, result.spans)
    }

    public func parseEntries(
        tokens: [EntryCompilerToken]
    ) throws -> [Entry] {
        try parsers.makeEntries(tokens, settings.entry.defaultTimezone).parseEntries()
    }

    public func compileFile(
        _ url: URL
    ) throws -> [Entry] {
        let src = try String(contentsOf: url, encoding: .utf8)
        let toks = lex(src)
        return try parseEntries(tokens: toks)
    }
}
