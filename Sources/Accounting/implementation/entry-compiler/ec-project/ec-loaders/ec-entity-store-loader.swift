import Foundation

public enum EntityStoreLoader {
    public static func load(
        from project: EntryCompilerProject,
        // defaultTZ: TimeZone,
        settings: EntryCompilerSettings,
        verbose: Bool = false,
        trace: Bool = true
    ) throws -> EntityStore {
        let root = project.url(.config).appendingPathComponent("entities", isDirectory: true)
        var builder = EntityStoreBuilder()

        let fm = FileManager.default
        if let e = fm.enumerator(at: root, includingPropertiesForKeys: nil) {
            for case let url as URL in e where url.pathExtension == "ec" {
                let src = try String(contentsOf: url, encoding: .utf8)
                var lx = EntryCompilerLexer(source: src, flavor: .entities)

                let toks: [EntryCompilerToken]
                let lineMap: [Int]?

                if trace {
                    (toks, lineMap) = lx.collectAllTokensWithLineMap()
                } else {
                    toks = lx.collectAllTokens()
                    lineMap = nil
                }

                let defs = try EntryCompilerEntitiesFileParser(
                    tokens: toks, 
                    defaultTZ: settings.entry.defaultTimezone,
                    fileURL: url,
                    lineMap: lineMap,
                    verbose: verbose
                )
                .parseEntitiesFile()
                for d in defs { try builder.add(d) }
                if verbose {
                    fputs("  ✓ \(url.lastPathComponent): \(defs.count) def(s)\n", stderr)
                }
            }
        }
        return builder.freeze()
    }
}
