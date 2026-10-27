import Foundation
import Primitives
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

    /// Use the date-completion invariant implemented in Primitives.
    /// Accounting retains its existing Codable and error contracts.
    public func resolved(using context: DateCompletionContext) throws -> DateSpecification {
        switch self {
        case .absolute:
            return self
        case .infer(let day):
            do {
                let primitive = Primitives.DateSpecification(infer: day)
                return .absolute(try primitive.resolve(using: context))
            } catch {
                throw EntryDateInferenceError.badDay(context.year, context.month, day.value)
            }
        }
    }

    /// Complete an inferred date from a validated project period, without reading a path.
    public func resolved(using period: EntrySourcePeriod, timezone: TimeZone) throws -> DateSpecification {
        try resolved(using: period.completionContext(timezone: timezone))
    }

    /// Compatibility boundary while source paths remain in Position.file.
    public func resolved(for entry: Entry, using settings: EntryCompilerSettings) throws -> DateSpecification {
        switch self {
        case .absolute:
            return self
        case .infer:
            guard let path = entry.location?.file, !path.isEmpty else {
                throw EntryDateInferenceError.badPath("<missing file path on entry>")
            }
            let period = try inferEntrySourcePeriod(from: path)
            let timezone = entry.timezone.flatMap(TimeZone.init(identifier:)) ?? settings.entry.defaultTimezone
            return try resolved(using: period, timezone: timezone)
        }
    }
}
