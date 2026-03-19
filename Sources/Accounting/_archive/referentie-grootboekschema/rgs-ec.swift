import Foundation

public enum EntryCompilerAccountsECWriter {
    @inline(__always)
    private static func filename(for root: RootNodeClass) -> String {
        switch root {
        case .asset:      return "assets.ec"
        case .liability:  return "liabilities.ec"
        case .equity:     return "equity.ec"
        case .revenue:    return "revenue.ec"
        case .expense:    return "expenses.ec"
        case .aggregated: return "aggregated.ec"
        }
    }

    /// single file export
    public static func writeSingleFile(to path: String, accounts: [RGSAccount]) throws {
        let body = accounts
            .sorted { $0.code < $1.code }
            .map { $0.writeAsEC() }
            .joined(separator: "\n")
        let url = URL(fileURLWithPath: path)
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try body.write(to: url, atomically: true, encoding: .utf8)
    }

    /// write per RootNodeClass (includes `.aggregated`)
    public static func writePerClass(into dir: String, accounts: [RGSAccount]) throws {
        let fm = FileManager.default
        try fm.createDirectory(atPath: dir, withIntermediateDirectories: true)

        let agg = RGSAccountAggregator(accounts: accounts)

        var buckets: [RootNodeClass: [RGSAccount]] = [:]
        for a in accounts {
            let root = try agg.rootBucket(for: a)
            buckets[root, default: []].append(a)
        }

        for root in RootNodeClass.allCases {
            guard let group = buckets[root], !group.isEmpty else { continue }
            let path = (dir as NSString).appendingPathComponent(filename(for: root))
            let body = group
                .sorted { $0.code < $1.code }
                .map { $0.writeAsEC() }
                .joined(separator: "\n")
            try body.write(toFile: path, atomically: true, encoding: .utf8)
        }
    }
}
