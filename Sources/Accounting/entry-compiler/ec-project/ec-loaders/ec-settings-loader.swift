import Foundation

public enum EntryCompilerSettingsLoaderError: Error, LocalizedError, Sendable {
    case fileNotFound(URL)
    case fileEmpty(URL)

    public var errorDescription: String? {
        switch self {
        case .fileNotFound(let url): 
            return """
            settings.ec not found at: \(url.path)
            note: ensure this is a valid accounting directory project
            """
        case .fileEmpty(let url):    
            return "settings.ec is empty at: \(url.path)"
        }
    }
}

public enum EntryCompilerSettingsLoader {
    public static func load(
        from projectRoot: URL
    ) throws -> EntryCompilerSettings {
        let url = projectRoot.appendingPathComponent("config/settings.ec")
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw EntryCompilerSettingsLoaderError.fileNotFound(url)
        }
        let src = try String(contentsOf: url, encoding: .utf8)
        guard src.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false else {
            throw EntryCompilerSettingsLoaderError.fileEmpty(url)
        }
        var lexer = EntryCompilerLexer(source: src, flavor: .settings)
        let (toks, lineMap) = lexer.collectAllTokensWithLineMap()

        let parser = EntryCompilerSettingsParser(
            tokens: toks,
            fileURL: url,
            lineMap: lineMap
        )
        return try parser.parseSettingsBlock()
    }
}
