import Foundation

// public enum AccountStoreLoader {
//     public static func load(
//         from project: EntryCompilerProject,
//         defaultTZ: TimeZone,
//         verbose: Bool = false
//     ) throws -> AccountStore {
//         let dir = project.url(.config).appendingPathComponent("accounts", isDirectory: true)
//         let fm = FileManager.default
//         var defs: [AccountDef] = []

//         if let e = fm.enumerator(at: dir, includingPropertiesForKeys: nil) {
//             for case let url as URL in e where url.pathExtension == "ec" {
//                 let src = try String(contentsOf: url, encoding: .utf8)
//                 var lx = EntryCompilerLexer(source: src, flavor: .accounts)
//                 let (toks, lineMap) = lx.collectAllTokensWithLineMap()

//                 let parser = EntryCompilerAccountsFileParser(
//                     tokens: toks,
//                     fileURL: url,
//                     lineMap: lineMap,
//                     verbose: verbose
//                 )
//                 let parsed = try parser.parseAccountsFile()
//                 defs.append(contentsOf: parsed)

//                 if verbose {
//                     fputs("  ✓ \(url.lastPathComponent): \(parsed.count) def(s)\n", stderr)
//                 }
//             }
//         }

//         // if you still want to honor defs later, convert them to nodes here. For now, skip.
//         return try AccountStore(base)
//     }

//     public static func load(from project: EntryCompilerProject, base: [RGSAccount]) throws -> AccountStore {
//         var builder = AccountStoreBuilder()
//         try builder.addBase(base)
//         return try builder.freeze()
//     }

//     public static func load(fromBase base: [RGSAccount]) throws -> AccountStore {
//         var b = AccountStoreBuilder()
//         try b.addBase(base)
//         return try b.freeze()
//     }
// }

public enum AccountStoreLoader {
    /// Loads project-local account defs (currently parsed but not applied) and returns an AccountStore.
    /// Prefers a compiled RGS chart at: <project.config>/rgs.compiled.json
    public static func load(
        from project: EntryCompilerProject,
        defaultTZ: TimeZone,
        verbose: Bool = false
    ) throws -> AccountStore {
        let fm = FileManager.default

        // 1) Parse any local account .ec files (kept for later, not applied yet)
        let dir = project.url(.config).appendingPathComponent("accounts", isDirectory: true)
        var defs: [AccountDef] = []
        if let e = fm.enumerator(at: dir, includingPropertiesForKeys: nil) {
            for case let url as URL in e where url.pathExtension == "ec" {
                let src = try String(contentsOf: url, encoding: .utf8)
                var lx = EntryCompilerLexer(source: src, flavor: .accounts)
                let (toks, lineMap) = lx.collectAllTokensWithLineMap()

                let parser = EntryCompilerAccountsFileParser(
                    tokens: toks,
                    fileURL: url,
                    lineMap: lineMap,
                    verbose: verbose
                )
                let parsed = try parser.parseAccountsFile()
                defs.append(contentsOf: parsed)
                if verbose { fputs("  ✓ \(url.lastPathComponent): \(parsed.count) def(s)\n", stderr) }
            }
        }
        // (Future) apply `defs` as presentation overrides; skipped for now.

        // 2) Prefer compiled chart if present
        // ABOUT VERSION: REPLACE THIS WITH SETTINGS OBJECT (pair with timezone?)
        // then we can pass it as a generic settings object -- requires struct?
        let version = ChartVersion(major: 3, minor: 8)
        let compiledChartURL = project.rgs(version: version)

        if fm.fileExists(atPath: compiledChartURL.path) {
            let data = try Data(contentsOf: compiledChartURL)
            let chart = try JSONDecoder().decode(CompiledChart.self, from: data)
            if verbose { fputs("  ✓ loaded compiled RGS chart (\(chart.nodes.count) nodes)\n", stderr) }
            return try AccountStore(chart: chart)
        }

        // 3) Fallback: empty store (we’re deferring mapping/aggregation for now)
        if verbose { fputs("  ! no rgs/<v#_#>.json; returning empty AccountStore\n", stderr) }
        return try AccountStore(nodes: [])
    }

    // Convenience shims for node-backed API only
    public static func load(using chart: CompiledChart) throws -> AccountStore {
        try AccountStore(chart: chart)
    }

    public static func load(using nodes: [RGSNode]) throws -> AccountStore {
        try AccountStore(nodes: nodes)
    }

    public static func empty() throws -> AccountStore {
        try AccountStore(nodes: [])
    }
}
