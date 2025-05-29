import Foundation

public struct RGSAccountConverter {
    public static func io(rawJSON input: String, converted output: String) throws {
        let i = URL(fileURLWithPath: input) 
        print(i)
        let o = URL(fileURLWithPath: output) 
        print(o)
        let rgsAccounts = try convert(rawJSON: i)
        print(rgsAccounts)
        try write(rgsAccounts, to: o)
    }

    public static func convert(rawJSON url: URL) throws -> [RGSAccount] {
        let data = try Data(contentsOf: url)
        let rawRows = try JSONDecoder().decode([RGSRawPDFTableObject].self, from: data)
        return rawRows.compactMap(RGSAccount.init(raw:))
    }

    public static func write(_ accounts: [RGSAccount], to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(accounts)
        try data.write(to: url)
    }
}
