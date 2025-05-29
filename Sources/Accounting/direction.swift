import Foundation

public enum Direction: String, Codable {
    case debit
    case credit

    public init(raw: String) {
        switch raw.uppercased() {
        case "D", "DR", Self.debit.rawValue.uppercased(), Self.debit.rawValue:
            self = .debit
        case "C", "CR", Self.credit.rawValue.uppercased(), Self.credit.rawValue:
            self = .credit
        default:
            preconditionFailure("Invalid Direction code: '\(raw)'")
        }
    }

    public init(from decoder: Decoder) throws {
        let s = try decoder.singleValueContainer().decode(String.self)
        self = Direction(raw: s)
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        try c.encode(self.rawValue)
    }
}
