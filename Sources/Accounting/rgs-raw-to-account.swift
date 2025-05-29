import Foundation

public struct RGSAccountConverter {
    public static func convert(rawJSONAt url: URL) throws -> [RGSAccount] {
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
