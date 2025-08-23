import Foundation

public enum AccountStoreLoader {
    public static func load(
        from project: EntryCompilerProject,
        defaultTZ: TimeZone,
        verbose: Bool = false // verbose vprint() not yet implemented
    ) throws -> AccountStore {
        let dir = project.url(.config).appendingPathComponent("accounts", isDirectory: true)
        let fm = FileManager.default
        var defs: [AccountDef] = []

        if let e = fm.enumerator(at: dir, includingPropertiesForKeys: nil) {
            for case let url as URL in e where url.pathExtension == "ec" {
                let src = try String(contentsOf: url, encoding: .utf8)
                var lx = EntryCompilerLexer(source: src)
                let (toks, lines) = lx.collectAllTokensWithLineMap()

                let core = EntryCompilerParserCore(tokens: toks, filePath: url.path, lineMap: lines)
                let parsed = try EntryCompilerAccountsFileParser(core: core).parseAccountsFile()
                defs.append(contentsOf: parsed)
            }
        }

        var b = AccountStoreBuilder()
        try b.addOverrides(defs)  // project config can fully define/override accounts
        return try b.freeze()
    }

    public static func load(from project: EntryCompilerProject, base: [RGSAccount]) throws -> AccountStore {
        var builder = AccountStoreBuilder()
        try builder.addBase(base)
        return try builder.freeze()
    }

    public static func load(fromBase base: [RGSAccount]) throws -> AccountStore {
        var b = AccountStoreBuilder()
        try b.addBase(base)
        return try b.freeze()
    }
}
