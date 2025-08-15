import Foundation
import plate

// public enum EntryDateError: Error {
//     case invalidLiteral(String)
//     case invalidComponents(DateComponents)
// }

// public enum DateLiteralPolicy {
//     /// Treat "2025-01-20" as a floating day; encode as 00:00:00Z (tests expect this).
//     case utcMidnight
//     /// Resolve the literal at 00:00 in the provided timezone, then convert to Date (an instant).
//     case resolveInTZ
// }

public enum DateSpecification: Hashable, Codable, Sendable, Equatable {
    case absolute(Date)
    case infer(day: Int)

    // static func absolute(fromLiteral s: String, tz: TimeZone, policy: DateLiteralPolicy) throws -> Date {
    //     let parts = try s.dateParts()
    //     let format: DateParserFormatting
    //     if parts[0].count == 4 { format = .yyyyMMdd }    // 2025-01-20
    //     else if parts[2].count == 4 { format = .ddMMyyyy } // 20-01-2025
    //     else { format = .yyyyMMdd }
    //     let comps = try format.components(from: parts)

    //     var cal = Calendar(identifier: .gregorian)
    //     switch policy {
    //     case .utcMidnight:
    //         cal.timeZone = TimeZone(secondsFromGMT: 0)!
    //     case .resolveInTZ:
    //         cal.timeZone = tz
    //     }
    //     guard let d = cal.date(from: comps) else { throw EntryDateError.invalidLiteral(s) }
    //     return d
    // }

    // static func absolute(fromComponents comps: DateComponents, tz: TimeZone) throws -> Date {
    //     var cal = Calendar(identifier: .gregorian)
    //     cal.timeZone = tz
    //     guard let d = cal.date(from: comps) else { throw EntryDateError.invalidComponents(comps) }
    //     return d
    // }

    private enum CodingKeys: String, CodingKey { case absolute, infer }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .absolute(let date):
            let iso = ISO8601DateFormatter()
            try container.encode(iso.string(from: date))
        case .infer(let day):
            try container.encode(["infer": day])
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let s = try? container.decode(String.self) {
            if let d = ISO8601DateFormatter().date(from: s) {
                self = .absolute(d)
                return
            }
        }
        if let dict = try? container.decode([String: Int].self),
           let day = dict["infer"] {
            self = .infer(day: day)
            return
        }
        throw DecodingError.dataCorruptedError(in: container,
            debugDescription: "Invalid DateSpecification format")
    }

}
