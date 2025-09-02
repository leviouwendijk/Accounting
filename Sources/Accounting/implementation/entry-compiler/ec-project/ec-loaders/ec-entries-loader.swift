import Foundation

public enum EntryCompilerEntriesLoader {
    public static func load(
        from project: EntryCompilerProject,
        // defaultTZ: TimeZone
        settings: EntryCompilerSettings,
        allowCollisions: Bool = false,
        onCollision: ((Int, String, String) -> Void)? = nil
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
                        if !allowCollisions {
                            throw EntryCompilerIntegrityError.idCollision(
                                kind: .entry, id: id, paths: [first, here]
                            )
                        } 
                        onCollision?(id, first, here)
                    }
                    seen[id] = here
                }
                out.append(contentsOf: entries)
            }
        }
        return out
    }

    public static func idCollisionString(
        id: Int,
        firstSeen: String,
        conflict: String
    ) -> String {
        return """
        ID COLLISION: \(id)
            \(firstSeen)
            \(conflict)
        """
    }
}

public final class CollisionReporter {
    private var seen = Set<String>() // key = "\(id)|\(first)|\(here)"

    public init() {}

    public func callback() -> (Int, String, String) -> Void {
        return { [weak self] id, first, here in
            guard let self = self else { return }
            let key = "\(id)|\(first)|\(here)"
            guard self.seen.insert(key).inserted else { return } // print once
            let msg = EntryCompilerEntriesLoader.idCollisionString(
                id: id, firstSeen: first, conflict: here
            )
            fputs(msg + "\n", stderr)
        }
    }
}
