import Foundation

public enum AccountStoreLoader {
    public static func load(from project: EntryCompilerProject) throws -> AccountStore {
        let dir = project.url(.config).appendingPathComponent("accounts", isDirectory: true)
        let fm = FileManager.default
        var defs: [AccountDef] = []

        if let e = fm.enumerator(at: dir, includingPropertiesForKeys: nil) {
            for case let url as URL in e where url.pathExtension == "ec" {
                let src = try String(contentsOf: url, encoding: .utf8)
                var lx = EntryCompilerLexer(source: src)
                let toks = lx.collectAllTokens()
                let parsed = try EntryCompilerAccountsFileParser(tokens: toks).parseAccountsFile()
                defs.append(contentsOf: parsed)
            }
        }

        var b = AccountStoreBuilder()
        try b.addOverrides(defs)               // allow accounts to be defined purely by config
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
