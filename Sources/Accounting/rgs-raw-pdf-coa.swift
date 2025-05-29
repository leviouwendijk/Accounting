import Foundation
import PDFKit

public struct RGSRawPDFTable: Codable {
    public let RekNr: String
    public let Omschrijving: String
    public let Nivo: String
    public let DC: String
    public let Omslag: String
    public let RGSCode: String
    public let ZZP: String
    public let EZ: String
    public let BV: String
    public let SVC: String
    public let Bra: String

    public init(
        RekNr: String,
        Omschrijving: String,
        Nivo: String,
        DC: String,
        Omslag: String,
        RGSCode: String,
        ZZP: String,
        EZ: String,
        BV: String,
        SVC: String,
        Bra: String
    ) {
        self.RekNr = RekNr
        self.Omschrijving = Omschrijving
        self.Nivo = Nivo
        self.DC = DC
        self.Omslag = Omslag
        self.RGSCode = RGSCode
        self.ZZP = ZZP
        self.EZ = EZ
        self.BV = BV
        self.SVC = SVC
        self.Bra = Bra
    }
}

public enum RGSRawPDFTableParserError: Error {
    case fileNotFound(String)
    case cannotReadPage(Int)
}

public struct RGSRawPDFTableParser {
    public static func io(input i: String, output o: String) throws {
        print("IO: \(i) -> \(o)")
        let rows = try RGSRawPDFTableParser.parse(path: i)
        print("Parsed \(rows.count) rows total")
        let data = try JSONEncoder().encode(rows)
        try data.write(to: URL(fileURLWithPath: o))
        print("Wrote JSON to \(o)")
    }

    public static func parse(path: String) throws -> [RGSRawPDFTable] {
        let url = URL(fileURLWithPath: path)
        guard let doc = PDFDocument(url: url) else {
            throw RGSRawPDFTableParserError.fileNotFound(path)
        }

        let pattern = #"(\d{1,5})\s+(.+?)\s+([234])\s+([DC])\s+(\S+)\s+(\S+)\s+([JN])\s+([JN])\s+([JN])\s+([JN])\s+([01])"#
        let regex = try NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators])

        var results: [RGSRawPDFTable] = []

        for i in 0..<doc.pageCount {
            guard let page = doc.page(at: i), let raw = page.string else {
                throw RGSRawPDFTableParserError.cannotReadPage(i+1)
            }
            // collapse newlines so our regex can span rows
            let text = raw.replacingOccurrences(of: "\n", with: " ")
            let ns = text as NSString
            let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: ns.length))
            print("Page \(i+1): found \(matches.count) records")
            for m in matches {
                let rek   = ns.substring(with: m.range(at: 1))
                let oms   = ns.substring(with: m.range(at: 2))
                let nivo  = ns.substring(with: m.range(at: 3))
                let dc    = ns.substring(with: m.range(at: 4))
                let omsl  = ns.substring(with: m.range(at: 5))
                let rgs   = ns.substring(with: m.range(at: 6))
                let zzp   = ns.substring(with: m.range(at: 7))
                let ez    = ns.substring(with: m.range(at: 8))
                let bv    = ns.substring(with: m.range(at: 9))
                let svc   = ns.substring(with: m.range(at: 10))
                let bra   = ns.substring(with: m.range(at: 11))

                let rec = RGSRawPDFTable(
                    RekNr:        rek,
                    Omschrijving: oms,
                    Nivo:         nivo,
                    DC:           dc,
                    Omslag:       omsl,
                    RGSCode:      rgs,
                    ZZP:          zzp,
                    EZ:           ez,
                    BV:           bv,
                    SVC:          svc,
                    Bra:          bra
                )
                results.append(rec)
            }
        }

        return results
    }
}
