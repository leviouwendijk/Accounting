import Foundation

public enum EntryCompilerTransactionsLoader {
    public static func load(
        from project: EntryCompilerProject,
        verbose: Bool = false,
        trace: Bool = true
    ) throws -> TransactionStore {
        let root = project.url(.transactions)
        var txs: [Transaction] = []
        let fm = FileManager.default

        if let e = fm.enumerator(at: root, includingPropertiesForKeys: nil) {
            for case let url as URL in e where url.pathExtension == "ec" {
                let src = try String(contentsOf: url, encoding: .utf8)
                var lx = EntryCompilerLexer(source: src, flavor: .transactions)

                let toks: [EntryCompilerToken]
                let lineMap: [Int]?

                if trace {
                    (toks, lineMap) = lx.collectAllTokensWithLineMap()
                } else {
                    toks = lx.collectAllTokens()
                    lineMap = nil
                }

                let parser = EntryCompilerTransactionsFileParser(
                    core: .init(
                        tokens: toks,
                        filePath: url.path,
                        lineMap: lineMap,
                        verbose: verbose
                    ),
                    fileURL: url
                )

                let parsed = try parser.parseTransactionsFile()
                txs.append(contentsOf: parsed)

                if verbose {
                    fputs("  ✓ \(url.lastPathComponent): \(txs.count) txn(s)\n", stderr)
                }
            }
        }
        return try TransactionStore(txs)
    }
}
