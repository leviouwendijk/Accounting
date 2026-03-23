import Foundation

public enum ECDocumentLoader {
    public static func load(
        from project: EntryCompilerProject,
        settings: EntryCompilerSettings,
        verbose: Bool = false,
        trace: Bool = true
    ) throws -> [ECDocument] {
        let root = project.url(.documents)
        let urls = ecFiles(at: root)

        if urls.isEmpty {
            return []
        }

        var out: [ECDocument] = []

        for url in urls {
            let src = try String(contentsOf: url, encoding: .utf8)
            var lx = EntryCompilerLexer(source: src, flavor: .entries)

            let toks: [EntryCompilerToken]
            let lineMap: [Int]?

            if trace {
                (toks, lineMap) = lx.collectAllTokensWithLineMap()
            } else {
                toks = lx.collectAllTokens()
                lineMap = nil
            }

            let parser = ECDocumentFileParser(
                core: .init(
                    tokens: toks,
                    filePath: url.path,
                    lineMap: lineMap,
                    verbose: verbose
                ),
                defaultTimeZone: settings.entry.defaultTimezone,
                fileURL: url
            )

            let parsed = try parser.parseDocumentsFile()
            out.append(contentsOf: parsed)

            if verbose {
                fputs("  ✓ \(url.lastPathComponent): \(parsed.count) document(s)\n", stderr)
            }
        }

        return out
    }
}
