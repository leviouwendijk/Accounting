import Foundation

public enum Direction: String, Codable {
    case debit
    case credit

    public init?(raw: String) {
        switch raw {
        case "D", "DR", Self.debit.rawValue:
            self = .debit
        case "C", "CR", Self.credit.rawValue:
            self = .credit
        default:
            return nil
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let s = try container.decode(String.self)
        guard let d = Direction(raw: s) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unknown direction: \(s)"
            )
        }
        self = d
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.rawValue)
    }
}
