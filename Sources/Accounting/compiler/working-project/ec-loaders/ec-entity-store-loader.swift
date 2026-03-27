import Foundation

public enum EntityStoreLoader {
    public static func load(
        from project: EntryCompilerProject,
        // defaultTZ: TimeZone,
        settings: EntryCompilerSettings,
        verbose: Bool = false,
        trace: Bool = true
    ) throws -> EntityStore {
        // let root = project.url(.config).appendingPathComponent("entities", isDirectory: true)
        let root = project.url(.config, .entities)
        var builder = EntityStoreBuilder()

        let fm = FileManager.default
        if let e = fm.enumerator(at: root, includingPropertiesForKeys: nil) {
            for case let url as URL in e where url.pathExtension == "ec" {
                let src = try String(contentsOf: url, encoding: .utf8)
                var lx = EntryCompilerLexer(source: src, flavor: .entities)

                let prepared = try lx.prepareTokenStream(
                    trace: trace,
                    filePath: url.path
                )

                let defs = try EntryCompilerEntitiesFileParser(
                    tokens: prepared.tokens,
                    defaultTZ: settings.entry.defaultTimezone,
                    fileURL: url,
                    lineMap: prepared.lineMap,
                    spanMap: prepared.spanMap,
                    verbose: verbose
                )
                .parseEntitiesFile()

                for d in defs {
                    try builder.add(d)
                }

                if verbose {
                    fputs("  ✓ \(url.lastPathComponent): \(defs.count) def(s)\n", stderr)
                }
            }
        }

        return builder.freeze()
    }

    public static func load(
        from project: EntryCompilerProject,
        settings: EntryCompilerSettings,
        verbose: Bool = false,
        trace: Bool = true
    ) async throws -> EntityStore {
        let root = project.url(.config, .entities)
        let urls = ecFiles(at: root)

        if urls.isEmpty {
            return EntityStoreBuilder().freeze()
        }

        struct FileEntities: Sendable {
            let file: URL
            let defs: [EntityDef]
        }

        let perFile: [FileEntities] = try await withThrowingTaskGroup(
            of: FileEntities.self
        ) { group in
            for url in urls {
                group.addTask {
                    let src = try String(contentsOf: url, encoding: .utf8)
                    var lx = EntryCompilerLexer(source: src, flavor: .entities)

                    let prepared = try lx.prepareTokenStream(
                        trace: trace,
                        filePath: url.path
                    )

                    let defs = try EntryCompilerEntitiesFileParser(
                        tokens: prepared.tokens,
                        defaultTZ: settings.entry.defaultTimezone,
                        fileURL: url,
                        lineMap: prepared.lineMap,
                        spanMap: prepared.spanMap,
                        verbose: verbose
                    )
                    .parseEntitiesFile()

                    if verbose {
                        fputs("  ✓ \(url.lastPathComponent): \(defs.count) def(s)\n", stderr)
                    }

                    return FileEntities(file: url, defs: defs)
                }
            }

            var out: [FileEntities] = []
            for try await fe in group {
                out.append(fe)
            }
            return out
        }

        var builder = EntityStoreBuilder()
        for fe in perFile {
            for d in fe.defs {
                try builder.add(d)
            }
        }

        return builder.freeze()
    }
}

// public enum EntityStoreLoader {
//     public static func load(
//         from project: EntryCompilerProject,
//         // defaultTZ: TimeZone,
//         settings: EntryCompilerSettings,
//         verbose: Bool = false,
//         trace: Bool = true
//     ) throws -> EntityStore {
//         // let root = project.url(.config).appendingPathComponent("entities", isDirectory: true)
//         let root = project.url(.config, .entities)
//         var builder = EntityStoreBuilder()

//         let fm = FileManager.default
//         if let e = fm.enumerator(at: root, includingPropertiesForKeys: nil) {
//             for case let url as URL in e where url.pathExtension == "ec" {
//                 let src = try String(contentsOf: url, encoding: .utf8)
//                 var lx = EntryCompilerLexer(source: src, flavor: .entities)

//                 let toks: [EntryCompilerToken]
//                 let lineMap: [Int]?

//                 if trace {
//                     (toks, lineMap) = lx.collectAllTokensWithLineMap()
//                 } else {
//                     toks = lx.collectAllTokens()
//                     lineMap = nil
//                 }

//                 let defs = try EntryCompilerEntitiesFileParser(
//                     tokens: toks, 
//                     defaultTZ: settings.entry.defaultTimezone,
//                     fileURL: url,
//                     lineMap: lineMap,
//                     verbose: verbose
//                 )
//                 .parseEntitiesFile()
//                 for d in defs { try builder.add(d) }
//                 if verbose {
//                     fputs("  ✓ \(url.lastPathComponent): \(defs.count) def(s)\n", stderr)
//                 }
//             }
//         }
//         return builder.freeze()
//     }

//     public static func load(
//         from project: EntryCompilerProject,
//         settings: EntryCompilerSettings,
//         verbose: Bool = false,
//         trace: Bool = true
//     ) async throws -> EntityStore {
//         let root = project.url(.config, .entities)
//         let urls = ecFiles(at: root)

//         if urls.isEmpty {
//             return EntityStoreBuilder().freeze()
//         }

//         struct FileEntities: Sendable {
//             let file: URL
//             let defs: [EntityDef]
//         }

//         let perFile: [FileEntities] = try await withThrowingTaskGroup(
//             of: FileEntities.self
//         ) { group in
//             for url in urls {
//                 group.addTask {
//                     let src = try String(contentsOf: url, encoding: .utf8)
//                     var lx = EntryCompilerLexer(source: src, flavor: .entities)

//                     let toks: [EntryCompilerToken]
//                     let lineMap: [Int]?

//                     if trace {
//                         (toks, lineMap) = lx.collectAllTokensWithLineMap()
//                     } else {
//                         toks = lx.collectAllTokens()
//                         lineMap = nil
//                     }

//                     let defs = try EntryCompilerEntitiesFileParser(
//                         tokens: toks,
//                         defaultTZ: settings.entry.defaultTimezone,
//                         fileURL: url,
//                         lineMap: lineMap,
//                         verbose: verbose
//                     )
//                     .parseEntitiesFile()

//                     if verbose {
//                         fputs("  ✓ \(url.lastPathComponent): \(defs.count) def(s)\n", stderr)
//                     }

//                     return FileEntities(file: url, defs: defs)
//                 }
//             }

//             var out: [FileEntities] = []
//             for try await fe in group {
//                 out.append(fe)
//             }
//             return out
//         }

//         var builder = EntityStoreBuilder()
//         for fe in perFile {
//             for d in fe.defs {
//                 try builder.add(d)
//             }
//         }

//         return builder.freeze()
//     }
// }
