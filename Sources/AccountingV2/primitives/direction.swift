import Foundation

public enum DirectionError: Error, CustomStringConvertible, Sendable {
    case invalidCode(String)
    case invalidInt8(Int8)

    public var description: String {
        switch self {
        case .invalidCode(let raw):
            return "Invalid Direction code: '\(raw)'"
        case .invalidInt8(let int):
            return "Direction sign must be 1 or -1, not: \(int)"
        }
    }
}

public enum Direction: String, Codable, Sendable {
    case debit
    case credit

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

    @inlinable 
    public init(sign: Int8) throws {
        switch sign {
            case 1:
                self = .debit
            case -1:
                self = .credit
            default:
                throw DirectionError.invalidInt8(sign)
        }
    }

    @inlinable
    public var int: Int8 {
        switch self {
            case .debit:
                return 1
            case .credit:
                return -1
        }
    }
}
