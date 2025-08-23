import Foundation

// public enum EntityStoreLoader {
//     public static func load(from project: EntryCompilerProject) throws -> EntityStore {
//         let root = project.url(.config).appendingPathComponent("entities", isDirectory: true)
//         var builder = EntityStoreBuilder()

//         let fm = FileManager.default
//         if let e = fm.enumerator(at: root, includingPropertiesForKeys: nil) {
//             for case let url as URL in e where url.pathExtension == "ec" {
//                 let (cls, fam) = inferClassFamily(from: url)
//                 let src = try String(contentsOf: url, encoding: .utf8)
//                 var lx = EntryCompilerLexer(source: src)
//                 let toks = lx.collectAllTokens()

//                 let defs = try EntryCompilerEntitiesFileParser(tokens: toks)
//                     .parseEntitiesFile(inferredClass: cls, inferredFamily: fam)

//                 for d in defs { try builder.add(d) }
//             }
//         }

//         return builder.freeze()
//     }
// }

// public enum EntityStoreLoader {
//     public static func load(from project: EntryCompilerProject) throws -> EntityStore {
//         let root = project.url(.config).appendingPathComponent("entities", isDirectory: true)
//         var builder = EntityStoreBuilder()

//         let fm = FileManager.default
//         if let e = fm.enumerator(at: root, includingPropertiesForKeys: nil) {
//             for case let url as URL in e where url.pathExtension == "ec" {
//                 let src = try String(contentsOf: url, encoding: .utf8)
//                 var lx = EntryCompilerLexer(source: src)
//                 let (toks, lines) = lx.collectAllTokensWithLineMap()

//                 let parserCore = EntryCompilerParserCore(tokens: toks, filePath: url.path, lineMap: lines)
//                 let defs = try EntryCompilerEntitiesFileParser(core: parserCore, fileURL: url)
//                     .parseEntitiesFile()

//                 for d in defs { try builder.add(d) }
//             }
//         }
//         return builder.freeze()
//     }
// }

public enum EntityStoreLoader {
    public static func load(
        from project: EntryCompilerProject,
        defaultTZ: TimeZone,
        verbose: Bool = false
    ) throws -> EntityStore {
        let root = project.url(.config).appendingPathComponent("entities", isDirectory: true)
        var builder = EntityStoreBuilder()

        let fm = FileManager.default
        if let e = fm.enumerator(at: root, includingPropertiesForKeys: nil) {
            for case let url as URL in e where url.pathExtension == "ec" {
                let src = try String(contentsOf: url, encoding: .utf8)
                var lx = EntryCompilerLexer(source: src)
                let toks = lx.collectAllTokens()
                let defs = try EntryCompilerEntitiesFileParser(
                    tokens: toks, 
                    fileURL: url, 
                    defaultTZ: defaultTZ,
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
