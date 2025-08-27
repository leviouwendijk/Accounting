import Foundation
import Extensions

public enum TemporalityError: Error, CustomStringConvertible, Sendable {
    case invalidCode(String)
    case invalidUInt8(UInt8)

    public var description: String {
        switch self {
        case .invalidCode(let raw):
            return "Invalid Direction code: '\(raw)'"
        case .invalidUInt8(let int):
            return "Direction sign must be 1 or -1, not: \(int)"
        }
    }
}

public enum Temporality: String, Codable, Sendable, StringParsableEnum {
    case instant
    case duration 

    public var help: String {
        switch self {
            case .instant:
                return "Directly to balance sheet, permanent"
            case .duration:
                return "Counted for a period, temporal"
        }
    }

    public init(raw: String) throws {
        let upper = raw.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        switch upper {
        case "permanent", "non-temporary", "non-temporal", Self.instant.rawValue.uppercased(), Self.instant.rawValue:
            self = .instant
        case "periodic", "temporary", "temporal", Self.duration.rawValue.uppercased(), Self.duration.rawValue:
            self = .duration
        default:
            throw TemporalityError.invalidCode(raw)
        }
    }

    public init(from decoder: Decoder) throws {
        let s = try decoder.singleValueContainer().decode(String.self)
        self = try Temporality(raw: s)
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        try c.encode(self.rawValue)
    }

    @inlinable 
    public init(sign: UInt8) throws {
        switch sign {
            case 0:
                self = .instant
            case 1:
                self = .duration
            default:
                throw TemporalityError.invalidUInt8(sign)
        }
    }

    @inlinable
    public var int: UInt8 {
        switch self {
            case .instant:
                return 0
            case .duration:
                return 1
        }
    }
}
