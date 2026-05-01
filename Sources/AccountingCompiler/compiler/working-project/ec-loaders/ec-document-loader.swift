import Accounting
import AccountingParsers
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
            var lx = EntryCompilerLexer(source: src, flavor: .documents)

            let prepared = try lx.prepareTokenStream(
                trace: trace,
                filePath: url.path
            )

            let parser = ECDocumentFileParser(
                core: .init(
                    tokens: prepared.tokens,
                    filePath: url.path,
                    lineMap: prepared.lineMap,
                    spanMap: prepared.spanMap,
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

// public enum ECDocumentLoader {
//     public static func load(
//         from project: EntryCompilerProject,
//         settings: EntryCompilerSettings,
//         verbose: Bool = false,
//         trace: Bool = true
//     ) throws -> [ECDocument] {
//         let root = project.url(.documents)
//         let urls = ecFiles(at: root)

//         if urls.isEmpty {
//             return []
//         }

//         var out: [ECDocument] = []

//         for url in urls {
//             let src = try String(contentsOf: url, encoding: .utf8)
//             var lx = EntryCompilerLexer(source: src, flavor: .documents)

//             let toks: [EntryCompilerToken]
//             let lineMap: [Int]?
//             let spanMap: [SourceSpan]?

//             if trace {
//                 // (toks, lineMap) = lx.collectAllTokensWithLineMap()

//                 let prepared = try lx.prepareTokenStream(
//                     trace: trace,
//                     filePath: url.path
//                 )
//                 lineMap = prepared.lineMap
//                 spanMap = prepared.spanMap
//             } else {
//                 toks = lx.collectAllTokens()
//                 lineMap = nil
//                 spanMap = nil
//             }

//             let parser = ECDocumentFileParser(
//                 core: .init(
//                     tokens: toks,
//                     filePath: url.path,
//                     lineMap: lineMap,
//                     spanMap: spanMap,
//                     verbose: verbose
//                 ),
//                 defaultTimeZone: settings.entry.defaultTimezone,
//                 fileURL: url
//             )

//             let parsed = try parser.parseDocumentsFile()
//             out.append(contentsOf: parsed)

//             if verbose {
//                 fputs("  ✓ \(url.lastPathComponent): \(parsed.count) document(s)\n", stderr)
//             }
//         }

//         return out
//     }
// }
