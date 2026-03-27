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

                let prepared = try lx.prepareTokenStream(
                    trace: trace,
                    filePath: url.path
                )

                let parser = EntryCompilerTransactionsFileParser(
                    core: .init(
                        tokens: prepared.tokens,
                        filePath: url.path,
                        lineMap: prepared.lineMap,
                        spanMap: prepared.spanMap,
                        verbose: verbose
                    ),
                    fileURL: url
                )

                let parsed = try parser.parseTransactionsFile()
                txs.append(contentsOf: parsed)

                if verbose {
                    fputs("  ✓ \(url.lastPathComponent): \(parsed.count) txn(s)\n", stderr)
                }
            }
        }
        return try TransactionStore(txs)
    }

    public static func load(
        from project: EntryCompilerProject,
        verbose: Bool = false,
        trace: Bool = true
    ) async throws -> TransactionStore {
        let root = project.url(.transactions)
        let urls = ecFiles(at: root)

        if urls.isEmpty {
            return try TransactionStore([])
        }

        let perFile: [[Transaction]] = try await withThrowingTaskGroup(
            of: [Transaction].self
        ) { group in
            for url in urls {
                group.addTask {
                    let src = try String(contentsOf: url, encoding: .utf8)
                    var lx = EntryCompilerLexer(source: src, flavor: .transactions)

                    let prepared = try lx.prepareTokenStream(
                        trace: trace,
                        filePath: url.path
                    )

                    let parser = EntryCompilerTransactionsFileParser(
                        core: .init(
                            tokens: prepared.tokens,
                            filePath: url.path,
                            lineMap: prepared.lineMap,
                            spanMap: prepared.spanMap,
                            verbose: verbose
                        ),
                        fileURL: url
                    )

                    let parsed = try parser.parseTransactionsFile()
                    if verbose {
                        fputs("  ✓ \(url.lastPathComponent): \(parsed.count) txn(s)\n", stderr)
                    }
                    return parsed
                }
            }

            var out: [[Transaction]] = []
            for try await tx in group {
                out.append(tx)
            }
            return out
        }

        var all: [Transaction] = []
        all.reserveCapacity(perFile.reduce(0) { $0 + $1.count })
        for txs in perFile {
            all.append(contentsOf: txs)
        }

        return try TransactionStore(all)
    }

    // public static func load(
    //     from project: EntryCompilerProject,
    //     verbose: Bool = false,
    //     trace: Bool = true
    // ) throws -> TransactionStore {
    //     let root = project.url(.transactions)
    //     var txs: [Transaction] = []
    //     let fm = FileManager.default

    //     if let e = fm.enumerator(at: root, includingPropertiesForKeys: nil) {
    //         for case let url as URL in e where url.pathExtension == "ec" {
    //             let src = try String(contentsOf: url, encoding: .utf8)
    //             var lx = EntryCompilerLexer(source: src, flavor: .transactions)

    //             let toks: [EntryCompilerToken]
    //             let lineMap: [Int]?

    //             if trace {
    //                 (toks, lineMap) = lx.collectAllTokensWithLineMap()
    //             } else {
    //                 toks = lx.collectAllTokens()
    //                 lineMap = nil
    //             }

    //             let parser = EntryCompilerTransactionsFileParser(
    //                 core: .init(
    //                     tokens: toks,
    //                     filePath: url.path,
    //                     lineMap: lineMap,
    //                     verbose: verbose
    //                 ),
    //                 fileURL: url
    //             )

    //             let parsed = try parser.parseTransactionsFile()
    //             txs.append(contentsOf: parsed)

    //             if verbose {
    //                 fputs("  ✓ \(url.lastPathComponent): \(txs.count) txn(s)\n", stderr)
    //             }
    //         }
    //     }
    //     return try TransactionStore(txs)
    // }

    // public static func load(
    //     from project: EntryCompilerProject,
    //     verbose: Bool = false,
    //     trace: Bool = true
    // ) async throws -> TransactionStore {
    //     let root = project.url(.transactions)
    //     let urls = ecFiles(at: root)

    //     if urls.isEmpty {
    //         return try TransactionStore([])
    //     }

    //     let perFile: [[Transaction]] = try await withThrowingTaskGroup(
    //         of: [Transaction].self
    //     ) { group in
    //         for url in urls {
    //             group.addTask {
    //                 let src = try String(contentsOf: url, encoding: .utf8)
    //                 var lx = EntryCompilerLexer(source: src, flavor: .transactions)

    //                 let toks: [EntryCompilerToken]
    //                 let lineMap: [Int]?

    //                 if trace {
    //                     (toks, lineMap) = lx.collectAllTokensWithLineMap()
    //                 } else {
    //                     toks = lx.collectAllTokens()
    //                     lineMap = nil
    //                 }

    //                 let parser = EntryCompilerTransactionsFileParser(
    //                     core: .init(
    //                         tokens: toks,
    //                         filePath: url.path,
    //                         lineMap: lineMap,
    //                         verbose: verbose
    //                     ),
    //                     fileURL: url
    //                 )

    //                 let parsed = try parser.parseTransactionsFile()
    //                 if verbose {
    //                     fputs("  ✓ \(url.lastPathComponent): \(parsed.count) txn(s)\n", stderr)
    //                 }
    //                 return parsed
    //             }
    //         }

    //         var out: [[Transaction]] = []
    //         for try await tx in group {
    //             out.append(tx)
    //         }
    //         return out
    //     }

    //     var all: [Transaction] = []
    //     all.reserveCapacity(perFile.reduce(0) { $0 + $1.count })
    //     for txs in perFile {
    //         all.append(contentsOf: txs)
    //     }

    //     return try TransactionStore(all)
    // }
}
