import Foundation

public enum EntryCompilerEntriesLoader {
    public static func load(
        from project: EntryCompilerProject,
        defaultTZ: TimeZone
    ) throws -> [Entry] {
        let root = project.url(.entries)
        var out: [Entry] = []
        let fm = FileManager.default

        if let e = fm.enumerator(at: root, includingPropertiesForKeys: nil) {
            for case let url as URL in e where url.pathExtension == "ec" {
                let src = try String(contentsOf: url, encoding: .utf8)
                var lx = EntryCompilerLexer(source: src)
                let toks = lx.collectAllTokens()
                let parser = EntryCompilerEntriesParser(tokens: toks, defaultTimeZone: defaultTZ)
                let entries = try parser.parseEntries()
                out.append(contentsOf: entries)
            }
        }
        return out
    }
}
