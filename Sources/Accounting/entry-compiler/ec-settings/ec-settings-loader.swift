import Foundation

public enum EntryCompilerSettingsLoaderError: Error, LocalizedError, Sendable {
    case fileNotFound(URL)
    case fileEmpty(URL)

    public var errorDescription: String? {
        switch self {
        case .fileNotFound(let url): return "settings.ec not found at: \(url.path)"
        case .fileEmpty(let url):    return "settings.ec is empty at: \(url.path)"
        }
    }
}

public enum EntryCompilerSettingsLoader {
    public static func load(from projectRoot: URL) throws -> EntryCompilerSettings {
        let url = projectRoot.appendingPathComponent("config/settings.ec")
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw EntryCompilerSettingsLoaderError.fileNotFound(url)
        }
        let src = try String(contentsOf: url, encoding: .utf8)
        guard src.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false else {
            throw EntryCompilerSettingsLoaderError.fileEmpty(url)
        }

        var lexer = EntryCompilerLexer(source: src)
        let toks = lexer.collectAllTokens() 

        return try EntryCompilerSettingsParser(tokens: toks).parseSettingsBlock()
    }
}
