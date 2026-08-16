import Foundation
import struct Primitives.DayOfMonth
import plate

public enum DateSpecification: Hashable, Codable, Sendable, Equatable {
    case absolute(Date)
    case infer(day: DayOfMonth)

    private enum CodingKeys: String, CodingKey { case absolute, infer }
    private enum LegacyAbsoluteKey: String, CodingKey { case _0 }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .absolute(let date):
            let iso = ISO8601DateFormatter()
            try c.encode(iso.string(from: date), forKey: .absolute)
        case .infer(let day):
            try c.encode(day.value, forKey: .infer)   // <— number, not {"day": …}
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
            let day: Int?

            if let direct =
                try? c.decode(
                    Int.self,
                    forKey: .infer
                )
            {
                day = direct
            } else if
                let object =
                    try? c.decode(
                        [String: Int].self,
                        forKey: .infer
                    )
            {
                day = object["day"]
            } else {
                day = nil
            }

            if let day {
                do {
                    self = .infer(
                        day: try DayOfMonth(
                            day
                        )
                    )

                    return
                } catch {
                    throw DecodingError
                        .dataCorruptedError(
                            forKey: .infer,
                            in: c,
                            debugDescription:
                                "Invalid inferred day: \(day)"
                        )
                }
            }
        }

        throw DecodingError.dataCorrupted(
            .init(codingPath: decoder.codingPath, debugDescription: "Invalid DateSpecification")
        )
    }

    public func resolved(for entry: Entry, using settings: EntryCompilerSettings) throws -> DateSpecification {
        let tz = entry.timezone.flatMap(TimeZone.init(identifier:)) ?? settings.entry.defaultTimezone

        switch self {
        case .absolute:
            return self
        case .infer(let day):
            guard let path = entry.location?.file, !path.isEmpty else {
                throw EntryDateInferenceError.badPath("<missing file path on entry>")
            }
            let (year, _, month) = try inferYearQuarterMonth(from: path)

            var cal = Calendar(identifier: .gregorian)
            cal.timeZone = tz

            var comps = DateComponents()
            comps.year = year
            comps.month = month
            comps.day = day.value

            guard let d = cal.date(from: comps) else {
                throw EntryDateInferenceError.badDay(
                    year,
                    month,
                    day.value
                )
            }
            return .absolute(d)
        }
    }
}
