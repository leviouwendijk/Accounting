import Foundation

public enum EntryCompilerAccountsECWriter {
    @inline(__always)
    private static func classFilename(_ cls: AccountClass) -> String? {
        switch cls {
        case .asset:     return "assets.ec"
        case .liability: return "liabilities.ec"
        case .equity:    return "equity.ec"
        case .revenue:   return "revenue.ec"
        case .expense:   return "expenses.ec"
        case .dividend:  return "dividends.ec"
        case .unknown:   return nil
        }
    }

    /// Writes all accounts into a single .ec file.
    public static func writeSingleFile(to path: String, accounts: [RGSAccount]) throws {
        let body = accounts
            .sorted { $0.code < $1.code }
            .map { $0.writeAsEC() }
            .joined(separator: "\n")
        try body.write(to: URL(fileURLWithPath: path), atomically: true, encoding: .utf8)
    }

    /// Writes per major class into `dir` (assets.ec, liabilities.ec, …).
    public static func writePerClass(into dir: String, accounts: [RGSAccount]) throws {
        let fm = FileManager.default
        try fm.createDirectory(atPath: dir, withIntermediateDirectories: true, attributes: nil)

        let grouped = Dictionary(grouping: accounts, by: { (acct) -> AccountClass in
            let n = Int(acct.code) ?? 0
            return (try? RGSAccountClassifier.classForRekNr(n)) ?? .unknown
        })

        for cls in AccountClass.allCases {
            guard let filename = classFilename(cls) else { continue }
            guard let group = grouped[cls], !group.isEmpty else { continue }
            let path = (dir as NSString).appendingPathComponent(filename)
            let body = group
                .sorted { $0.code < $1.code }
                .map { $0.writeAsEC() }
                .joined(separator: "\n")
            try body.write(toFile: path, atomically: true, encoding: .utf8)
        }
    }
}
