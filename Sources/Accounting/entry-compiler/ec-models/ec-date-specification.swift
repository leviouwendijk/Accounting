import Foundation
import plate

public enum DateSpecification: Hashable, Codable, Sendable, Equatable {
    case absolute(Date)
    case infer(day: Int)

    private enum CodingKeys: String, CodingKey { case absolute, infer }
    private enum LegacyAbsoluteKey: String, CodingKey { case _0 }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .absolute(let date):
            let iso = ISO8601DateFormatter()
            try c.encode(iso.string(from: date), forKey: .absolute)
        case .infer(let day):
            try c.encode(day, forKey: .infer)   // <— number, not {"day": …}
        }
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        if c.contains(.absolute) {
            if let s = try? c.decode(String.self, forKey: .absolute),
               let d = ISO8601DateFormatter().date(from: s) {
                self = .absolute(d); return
            }
            let nested = try c.nestedContainer(keyedBy: LegacyAbsoluteKey.self, forKey: .absolute)
            let s = try nested.decode(String.self, forKey: ._0)
            if let d = ISO8601DateFormatter().date(from: s) {
                self = .absolute(d)
                return
            }
        }

        if c.contains(.infer) {
            if let day = try? c.decode(Int.self, forKey: .infer) {
                self = .infer(day: day); return
            }
            if let obj = try? c.decode([String:Int].self, forKey: .infer),
               let day = obj["day"] {
                self = .infer(day: day); return
            }
        }

        throw DecodingError.dataCorrupted(
            .init(codingPath: decoder.codingPath, debugDescription: "Invalid DateSpecification")
        )
    }
}

public enum DateInferenceError: Error { case missingYearMonth(String) }

func resolveDate(_ spec: DateSpecification, filePath: String?, tz: TimeZone) throws -> Date {
    switch spec {
    case .absolute(let d):
        return d

    case .infer(let day):
        guard let filePath, !filePath.isEmpty else {
            throw DateInferenceError.missingYearMonth("no file path on entry")
        }
        // Support both: .../2025/1/1.ec  and  .../2025/1/1/main.ec
        let fileURL = URL(fileURLWithPath: filePath)
        // work with directories; drop the filename
        var comps = fileURL.deletingLastPathComponent().pathComponents

        // If last directory is a numeric day (1–31), drop it; month is the one before.
        if let last = comps.last, let d = Int(last), (1...31).contains(d) {
            comps.removeLast()
        }

        guard let monthStr = comps.last, let month = Int(monthStr), (1...12).contains(month) else {
            throw DateInferenceError.missingYearMonth("month not found in path: \(filePath)")
        }
        comps.removeLast()

        // Year is the previous numeric (e.g. 2025)
        guard let yearStr = comps.last, let year = Int(yearStr), (1900...2100).contains(year) else {
            throw DateInferenceError.missingYearMonth("year not found in path: \(filePath)")
        }

        var dc = DateComponents()
        dc.calendar = Calendar(identifier: .gregorian)
        dc.timeZone = tz
        dc.year = year
        dc.month = month
        dc.day = day
        guard let full = dc.date else {
            throw DateInferenceError.missingYearMonth("invalid Y/M/D from path: \(filePath)")
        }
        return full
    }
}
