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
        // defaultTZ: TimeZone,
        settings: EntryCompilerSettings,
        verbose: Bool = false
    ) throws -> AccountStore {
        let fm = FileManager.default

        // 1) Prefer compiled chart if present — fast path, NO .ec parsing
        let compiledChartURL = project.resource(
            finding: settings.aggregation.chartFind,
            version: settings.aggregation.chartVersion
        )

        if fm.fileExists(atPath: compiledChartURL.path) {
            let data = try Data(contentsOf: compiledChartURL)
            let chart = try JSONDecoder().decode(CompiledChart.self, from: data)
            if verbose { fputs("  ✓ loaded compiled RGS chart (\(chart.nodes.count) nodes)\n", stderr) }

            // Build node-backed store (no project .ec parsing / override prints)
            return try AccountStore(chart: chart)
        }

        // // 2) Fallback: parse local config/accounts/*.ec (legacy behavior)
        // let dir = project.url(.config).appendingPathComponent("accounts", isDirectory: true)
        // var defs: [AccountDef] = []
        // if let e = fm.enumerator(at: dir, includingPropertiesForKeys: nil) {
        //     for case let url as URL in e where url.pathExtension == "ec" {
        //         let src = try String(contentsOf: url, encoding: .utf8)
        //         var lx = EntryCompilerLexer(source: src, flavor: .accounts)
        //         let (toks, lineMap) = lx.collectAllTokensWithLineMap()

        //         let parser = EntryCompilerAccountsFileParser(
        //             tokens: toks,
        //             fileURL: url,
        //             lineMap: lineMap,
        //             verbose: verbose
        //         )
        //         let parsed = try parser.parseAccountsFile()
        //         defs.append(contentsOf: parsed)
        //         if verbose { fputs("  ✓ \(url.lastPathComponent): \(parsed.count) def(s)\n", stderr) }
        //     }
        // }

        // var builder = AccountStoreBuilder()
        // try builder.addOverrides(defs)   // legacy builder path
        // return try builder.freeze()

        // remove RGSAccount fallback until further notice
        // require use of JSON chart of accounts (config/resources/rgs/v#_#.json)
        throw AccountStoreError.empty(at: SourceLocation(file: compiledChartURL.path, line: 0, column: 0))
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
