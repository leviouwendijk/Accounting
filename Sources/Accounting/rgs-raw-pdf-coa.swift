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

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(RekNr,        forKey: .RekNr)
        try c.encode(Omschrijving, forKey: .Omschrijving)
        try c.encode(Nivo,         forKey: .Nivo)
        try c.encode(DC,           forKey: .DC)
        try c.encode(Omslag,       forKey: .Omslag)
        try c.encode(RGSCode,      forKey: .RGSCode)
        try c.encode(ZZP,          forKey: .ZZP)
        try c.encode(EZ,           forKey: .EZ)
        try c.encode(BV,           forKey: .BV)
        try c.encode(SVC,          forKey: .SVC)
        try c.encode(Bra,          forKey: .Bra)
    }
}

public enum RGSRawPDFTableParserError: Error {
    case fileNotFound(String)
    case cannotReadPage(Int)
    case headerNotFound
    case jsonEncodingFailed
}

public struct RGSRawPDFTableParser {
    public static func io(input i: String, output o: String) throws {
        print("IO: \(i) -> \(o)")
        let rows = try parse(path: i)
        print("Parsed \(rows.count) rows total")
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        guard let data = try? encoder.encode(rows) else {
            throw RGSRawPDFTableParserError.jsonEncodingFailed
        }
        try data.write(to: URL(fileURLWithPath: o))
        print("Wrote JSON to \(o)")
    }

    public static func parse(path: String) throws -> [RGSRawPDFTable] {
        guard let doc = PDFDocument(url: URL(fileURLWithPath: path)) else {
            throw RGSRawPDFTableParserError.fileNotFound(path)
        }

        guard let firstPage = doc.page(at: 0),
              let fullText = firstPage.string as NSString? else {
            throw RGSRawPDFTableParserError.cannotReadPage(1)
        }

        let headerWords = ["RekNr","Omschrijving","Nivo","DC","Omslag","RGS-code","ZZP","EZ","BV","SVC","Bra"]
        let lines = fullText
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }

        guard let headerLine = lines.first(where: { line in
            headerWords.allSatisfy { line.range(of: $0, options: .caseInsensitive) != nil }
        }) else {
            throw RGSRawPDFTableParserError.headerNotFound
        }

        let headerLineRange = fullText.range(of: headerLine, options: .caseInsensitive)
        var columnRects: [CGRect] = []
        for word in headerWords {
            let local = (headerLine as NSString).range(of: word, options: .caseInsensitive)
            guard local.location != NSNotFound else { continue }
            let pageRange = NSRange(
                location: headerLineRange.location + local.location,
                length: local.length
            )
            guard let sel = firstPage.selection(for: pageRange) else { continue }
            columnRects.append(sel.bounds(for: firstPage))
        }
        columnRects.sort { $0.minX < $1.minX }

        let mediaRect = firstPage.bounds(for: .mediaBox)
        let xs = columnRects.map { $0.minX - 2 }
        let columnSlices: [CGRect] = zip(xs, xs.dropFirst() + [mediaRect.maxX - 10]).map { x1, x2 in
            CGRect(x: x1, y: mediaRect.minY, width: x2 - x1, height: mediaRect.height)
        }

        var results: [RGSRawPDFTable] = []
        for pageIndex in 0..<doc.pageCount {
            guard let page = doc.page(at: pageIndex),
                  let pageSel = page.selection(for: mediaRect) else {
                throw RGSRawPDFTableParserError.cannotReadPage(pageIndex+1)
            }

            let lines = pageSel.selectionsByLine()
            for lineSel in lines {
                let lb = lineSel.bounds(for: page)
                let cells = columnSlices.map { slice -> String in
                    let r = CGRect(x: slice.minX, y: lb.minY, width: slice.width, height: lb.height)
                    return page.selection(for: r)?
                        .string?
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                        ?? ""
                }
                if cells.count == 11,
                   cells[0].range(of: "RekNr", options: .caseInsensitive) == nil
                {
                    let rec = RGSRawPDFTable(
                        RekNr:        cells[0],
                        Omschrijving: cells[1],
                        Nivo:         cells[2],
                        DC:           cells[3],
                        Omslag:       cells[4],
                        RGSCode:      cells[5],
                        ZZP:          cells[6],
                        EZ:           cells[7],
                        BV:           cells[8],
                        SVC:          cells[9],
                        Bra:          cells[10]
                    )
                    results.append(rec)
                }
            }
        }

        results = results.filter { rec in
            Int(rec.RekNr) != nil
        }

        var seen = Set<String>()
        let unique = results.filter { rec in
            let key = rec.RekNr + "-" + rec.Nivo
            guard !seen.contains(key) else { return false }
            seen.insert(key)
            return true
        }

        return unique
    }
}
