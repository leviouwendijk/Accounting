import Foundation

public enum EntryCompilerEntriesLoader {
    public static func load(
        from project: EntryCompilerProject,
        // defaultTZ: TimeZone
        settings: EntryCompilerSettings
    ) throws -> [Entry] {
        let root = project.url(.entries)
        var out: [Entry] = []
        var seen: [Int: String] = [:]     // id → first location (file:line:col)

        let fm = FileManager.default
        if let e = fm.enumerator(at: root, includingPropertiesForKeys: nil) {
            for case let url as URL in e where url.pathExtension == "ec" {
                let src = try String(contentsOf: url, encoding: .utf8)
                var lx = EntryCompilerLexer(source: src, flavor: .entries)
                let (toks, lineMap) = lx.collectAllTokensWithLineMap()
                let parser = EntryCompilerEntriesParser(
                    tokens: toks,
                    defaultTimeZone: settings.entry.defaultTimezone,
                    fileURL: url,
                    lineMap: lineMap
                )
                let entries = try parser.parseEntries()
                
                // check uniqueness
                for en in entries {
                    guard let id = en.id else { continue }
                    let here = en.location?.description ?? url.path  // "file:line:col"
                    if let first = seen[id] {
                        throw EntryCompilerIntegrityError.idCollision(
                            kind: .entry, id: id, paths: [first, here]
                        )
                    }
                    seen[id] = here
                }

                out.append(contentsOf: entries)
            }
        }
        return out
    }
}
