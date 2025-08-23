import Foundation

public struct EntryCompiler: Sendable {
    public let project: EntryCompilerProject
    public let parsers: EntryCompilerParsers
    public let settings: EntryCompilerSettings
    public let entities: EntityStore

    public init(root: URL, parsers: EntryCompilerParsers = .default) throws {
        self.project  = .init(root: root)
        self.parsers  = parsers
        self.settings = try parsers.makeSettings(root)
        self.entities = try EntityStoreLoader.load(
            from: self.project,
            defaultTZ: settings.entry.defaultTimezone,
            verbose: false
        )
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
