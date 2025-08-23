import Foundation

public enum EntryCompilerTransactionsLoader {
    public static func load(
        from project: EntryCompilerProject
    ) throws -> TransactionStore {
        let root = project.url(.transactions)
        var txs: [Transaction] = []
        let fm = FileManager.default

        if let e = fm.enumerator(at: root, includingPropertiesForKeys: nil) {
            for case let url as URL in e where url.pathExtension == "ec" {
                let src = try String(contentsOf: url, encoding: .utf8)
                var lx = EntryCompilerLexer(source: src)
                let toks = lx.collectAllTokens()
                let parsed = try EntryCompilerTransactionsFileParser(tokens: toks).parseTransactionsFile()
                txs.append(contentsOf: parsed)
            }
        }
        return try TransactionStore(txs)
    }
}
