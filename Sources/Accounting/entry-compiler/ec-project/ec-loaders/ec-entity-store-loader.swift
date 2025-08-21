import Foundation

public enum EntityStoreLoader {
    public static func load(from project: EntryCompilerProject) throws -> EntityStore {
        let root = project.url(.config).appendingPathComponent("entities", isDirectory: true)
        var builder = EntityStoreBuilder()

        let fm = FileManager.default
        if let e = fm.enumerator(at: root, includingPropertiesForKeys: nil) {
            for case let url as URL in e where url.pathExtension == "ec" {
                let (cls, fam) = inferClassFamily(from: url)
                let src = try String(contentsOf: url, encoding: .utf8)
                var lx = EntryCompilerLexer(source: src)
                let toks = lx.collectAllTokens()

                let defs = try EntryCompilerEntitiesFileParser(tokens: toks)
                    .parseEntitiesFile(inferredClass: cls, inferredFamily: fam)

                for d in defs { try builder.add(d) }
            }
        }

        return builder.freeze()
    }
}
