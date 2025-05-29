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

public struct RGSRawPDFPDFTableParser {
    public static func parse(path: String) throws -> [RGSRawPDFTable] {
        let url = URL(fileURLWithPath: path)
        guard let doc = PDFDocument(url: url) else {
            throw RGSRawPDFTableParserError.fileNotFound(path)
        }

        var results: [RGSRawPDFTable] = []
        let digitLine = try NSRegularExpression(pattern: #"^\d"#, options: [])
        let splitCols = try NSRegularExpression(pattern: #" {2,}"#, options: [])

        for i in 0..<doc.pageCount {
            guard let page = doc.page(at: i),
                  let text = page.string else {
                throw RGSRawPDFTableParserError.cannotReadPage(i+1)
            }

            let lines = text.components(separatedBy: .newlines)
            for raw in lines {
                let line = raw.trimmingCharacters(in: .whitespaces)
                if digitLine.firstMatch(in: line, options: [], range: NSRange(location: 0, length: line.utf16.count)) == nil {
                    continue
                }
                let ns = line as NSString
                let ranges = splitCols.matches(in: line, options: [], range: NSRange(location: 0, length: ns.length))
                var cols: [String] = []
                var lastEnd = 0
                for m in ranges {
                    let segment = ns.substring(with: NSRange(location: lastEnd, length: m.range.location - lastEnd))
                    cols.append(segment.trimmingCharacters(in: .whitespaces))
                    lastEnd = m.range.location + m.range.length
                }
                cols.append(ns.substring(from: lastEnd).trimmingCharacters(in: .whitespaces))
                guard cols.count >= 9 else { continue }

                let firstCell = cols[0]
                let parts = firstCell.split(separator: "\n", maxSplits: 1).map(String.init)
                let rek = parts[0]
                let oms = parts.count > 1 ? parts[1] : cols[1]

                let rec = RGSRawPDFTable(
                    RekNr:        rek,
                    Omschrijving: oms,
                    Nivo:         cols[1],
                    DC:           cols[2],
                    Omslag:       cols[3],
                    RGSCode:      cols[4],
                    ZZP:          cols[5].split(separator: " ").map(String.init).first ?? "",
                    EZ:           cols[5].split(separator: " ").map(String.init).dropFirst().first ?? "",
                    BV:           cols[6],
                    SVC:          cols[7],
                    Bra:          cols[8]
                )
                results.append(rec)
            }
        }

        return results
    }
}
