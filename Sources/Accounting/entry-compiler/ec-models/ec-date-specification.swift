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
