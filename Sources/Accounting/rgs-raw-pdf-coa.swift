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
        print("IO: \(i) → \(o)")
        let rows = try RGSRawPDFTableParser.parse(path: i)
        print("📝 Parsed \(rows.count) rows total")
        let data = try JSONEncoder().encode(rows)
        try data.write(to: URL(fileURLWithPath: o))
        print("Wrote JSON to \(o)")
    }

    public static func parse(path: String) throws -> [RGSRawPDFTable] {
        print("Opening PDF at \(path)")
        let url = URL(fileURLWithPath: path)
        guard let doc = PDFDocument(url: url) else {
            throw RGSRawPDFTableParserError.fileNotFound(path)
        }

        print("📄 PDF has \(doc.pageCount) pages\n")
        var results: [RGSRawPDFTable] = []
        let digitLine = try NSRegularExpression(pattern: #"^\d"#, options: [])
        let splitCols = try NSRegularExpression(pattern: #" {2,}"#, options: [])

        for i in 0..<doc.pageCount {
            guard let page = doc.page(at: i),
                  let text = page.string else {
                print("Cannot read page \(i+1)")
                throw RGSRawPDFTableParserError.cannotReadPage(i+1)
            }
            print("Page \(i+1): scanning lines…")
            let lines = text.components(separatedBy: .newlines)
            for (lineno, raw) in lines.enumerated() {
                let line = raw.trimmingCharacters(in: .whitespaces)
                let range = NSRange(location: 0, length: line.utf16.count)
                if digitLine.firstMatch(in: line, options: [], range: range) == nil {
                    continue
                }
                print(" → Matched data line \(lineno+1): \(line)")

                let ns = line as NSString
                let matches = splitCols.matches(in: line, options: [], range: NSRange(location: 0, length: ns.length))
                var cols: [String] = []
                var lastEnd = 0
                for m in matches {
                    let seg = ns.substring(with: NSRange(location: lastEnd, length: m.range.location - lastEnd))
                    cols.append(seg.trimmingCharacters(in: .whitespaces))
                    lastEnd = m.range.location + m.range.length
                }
                cols.append(ns.substring(from: lastEnd).trimmingCharacters(in: .whitespaces))

                if cols.count < 9 {
                    print("    Skipping: only \(cols.count) columns (need ≥9)")
                    continue
                }
                print("    ↳ Columns: \(cols)")

                let firstCell = cols[0]
                let parts = firstCell.split(separator: "\n", maxSplits: 1).map(String.init)
                let rek = parts[0]
                let oms = parts.count > 1 ? parts[1] : cols[1]
                print("    ↳ RekNr=\(rek), Oms=\(oms)")

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
                print("    Added record for code \(rek)\n")
            }
        }
        return results
    }
}
