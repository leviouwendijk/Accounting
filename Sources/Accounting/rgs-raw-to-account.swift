import Foundation

public struct RGSAccountConverter {
    public static func io(rawJSON input: String, converted output: String) throws {
        let i = URL(fileURLWithPath: input) 
        let o = URL(fileURLWithPath: output) 
        let rgsAccounts = try convert(rawJSON: i)
        print("rgs accounts from json: \(rgsAccounts.count)")
        try write(rgsAccounts, to: o)
    }

    public static func convert(rawJSON url: URL) throws -> [RGSAccount] {
        let data    = try Data(contentsOf: url)
        let rawRows = try JSONDecoder().decode([RGSRawPDFTableObject].self, from: data)
        print("decoded raw rows: \(rawRows.count)")

        let accounts = rawRows.compactMap { rawRow -> RGSAccount? in
            do {
                return try RGSAccount(raw: rawRow)
            } catch {
                // Log and skip this row
                print("skipping row (code=\(rawRow.RekNr)) due to error: \(error)")
                return nil
            }
        }

        print("kept \(accounts.count) accounts")
        return accounts
    }

    public static func write(_ accounts: [RGSAccount], to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(accounts)
        try data.write(to: url)
    }
}
