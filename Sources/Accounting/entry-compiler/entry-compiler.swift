import Foundation
import plate

public struct EntryCompilerParsers: Sendable {
    public let makeSettings: @Sendable (_ root: URL) throws -> EntryCompilerSettings
    public let makeEntries:  @Sendable (_ tokens: [EntryCompilerToken], _ defaultTZ: TimeZone) -> EntryCompilerEntriesParser

    public init(
        makeSettings: @Sendable @escaping (_ root: URL) throws -> EntryCompilerSettings,
        makeEntries:  @Sendable @escaping (_ tokens: [EntryCompilerToken], _ defaultTZ: TimeZone) -> EntryCompilerEntriesParser
    ) {
        self.makeSettings = makeSettings
        self.makeEntries  = makeEntries
    }

    public static var `default`: EntryCompilerParsers {
        .init(
            makeSettings: { try EntryCompilerSettingsLoader.load(from: $0) },
            makeEntries:  { tokens, tz in EntryCompilerEntriesParser(tokens: tokens, defaultTimeZone: tz) }
        )
    }
}

public struct EntryCompiler: Sendable {
    public let project: EntryCompilerProject
    public let parsers: EntryCompilerParsers
    public let settings: EntryCompilerSettings

    public init(root: URL, parsers: EntryCompilerParsers = .default) throws {
        self.project  = .init(root: root)
        self.parsers  = parsers
        self.settings = try parsers.makeSettings(root)
    }

    public func lex(_ source: String) -> [EntryCompilerToken] {
        var lx = EntryCompilerLexer(source: source)
        var out: [EntryCompilerToken] = []
        while true {
            let t = lx.nextToken()
            out.append(t)
            if t == .eof { break }
        }
        return out
    }

    public func lexWithLineMap(_ source: String) -> ([EntryCompilerToken], [Int]) {
        var lx = EntryCompilerLexer(source: source)
        return lx.collectAllTokensWithLineMap()
    }

    public func parseEntries(tokens: [EntryCompilerToken]) throws -> [Entry] {
        try parsers.makeEntries(tokens, settings.entry.defaultTimezone).parseEntries()
    }

    public func compileFile(_ url: URL) throws -> [Entry] {
        let src  = try String(contentsOf: url, encoding: .utf8)
        let toks = lex(src)
        return try parseEntries(tokens: toks)
    }
}
