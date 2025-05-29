import Foundation

public enum DirectionError: Error, CustomStringConvertible {
    case invalidCode(String)

    public var description: String {
        switch self {
        case .invalidCode(let raw):
            return "Invalid Direction code: '\(raw)'"
        }
    }
}

public enum Direction: String, Codable {
    case debit
    case credit

    /// Now throws instead of crashing
    public init(raw: String) throws {
        let upper = raw.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        switch upper {
        case "D", "DR", Self.debit.rawValue.uppercased(), Self.debit.rawValue:
            self = .debit
        case "C", "CR", Self.credit.rawValue.uppercased(), Self.credit.rawValue:
            self = .credit
        default:
            throw DirectionError.invalidCode(raw)
        }
    }

    public init(from decoder: Decoder) throws {
        let s = try decoder.singleValueContainer().decode(String.self)
        self = try Direction(raw: s)
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        try c.encode(self.rawValue)
    }
}
