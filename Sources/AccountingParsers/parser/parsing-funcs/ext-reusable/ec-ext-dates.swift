import Foundation
import Accounting
import Position
import struct Primitives.DayOfMonth

public extension EntryCompilerParsing {
    @inlinable
    func parseNamedDateOrInferIfPresent(
        names: [String],
        tz: TimeZone,
        allowInfer: Bool = false,
        allowUnixEpoch: Bool = false
    ) throws -> (matched: String, spec: DateSpecification)?
    {
        guard let matched = matchNameToken(names) else { return nil }
        advance()

        if current == .equals {
            advance()
            switch current {
            case let .dateLiteral(txt):
                let d = try parseDateLiteral(txt, in: tz); advance()
                return (matched, .absolute(d))

            case .lBrace:
                let d = try parseDateBlock(tz: tz) // consumes the closing brace
                return (matched, .absolute(d))

            case let .number(n) where allowUnixEpoch:
                let d = Date(timeIntervalSince1970: (n as NSDecimalNumber).doubleValue); advance()
                return (matched, .absolute(d))

            default:
                throw ParserError.unexpectedToken(current, expected: "date literal or { … }", at: loc())
            }
        }

        if allowInfer {
            guard current == .ident("infer") || current == .keyword("infer") else {
                throw ParserError.unexpectedToken(current, expected: "infer <day>", at: loc())
            }
            advance()
            guard case let .number(n) = current else {
                throw ParserError.unexpectedToken(current, expected: "number (day of month)", at: loc())
            }
            let day = (n as NSDecimalNumber).intValue
            advance()
            return (
                matched,
                .infer(
                    day: try DayOfMonth(
                        day
                    )
                )
            )
        }

        switch current {
        case let .dateLiteral(txt):
            let d = try parseDateLiteral(txt, in: tz); advance()
            return (matched, .absolute(d))
        case .lBrace:
            let d = try parseDateBlock(tz: tz)
            return (matched, .absolute(d))
        default:
            throw ParserError.unexpectedToken(current, expected: "date literal or { … }", at: loc())
        }
    }

    @inlinable
    func parseNamedDateOrInferExpecting(
        names: [String],
        tz: TimeZone,
        allowInfer: Bool = false,
        allowUnixEpoch: Bool = false
    ) throws -> (matched: String, spec: DateSpecification)
    {
        guard let result = try parseNamedDateOrInferIfPresent(
            names: names, tz: tz, allowInfer: allowInfer, allowUnixEpoch: allowUnixEpoch
        ) else {
            throw ParserError.unexpectedToken(current, expected: names.joined(separator: " / "), at: loc())
        }
        return result
    }

    @inlinable
    func parseDateOrInfer(tz: TimeZone, allowUnixEpoch: Bool = false) throws -> DateSpecification {
        try parseNamedDateOrInferExpecting(
            names: ["date"],
            tz: tz,
            allowInfer: true,
            allowUnixEpoch: allowUnixEpoch
        ).spec
    }

    /// Effective date (no infer), returns ISO 8601 string.
    @inlinable
    func parseEffectiveDateISO8601(tz: TimeZone) throws -> String {
        let (_, spec) = try parseNamedDateOrInferExpecting(names: ["effective_date"], tz: tz, allowInfer: false)
        let d = try spec.asAbsolute(loc: loc()) // see helper below
        return ISO8601DateFormatter().string(from: d)
    }

    @inlinable
    func parseCommissionDate(tz: TimeZone) throws -> Date {
        let (_, spec) = try parseNamedDateOrInferExpecting(names: ["commission_date"], tz: tz, allowInfer: false)
        return try spec.asAbsolute(loc: loc())
    }

    // @inline(__always)
    // func matchNameToken(_ names: [String]) -> String? {
    //     switch current {
    //     case let .ident(s) where names.contains(s):   return s
    //     case let .keyword(s) where names.contains(s): return s
    //     default: return nil
    //     }
    // }

    @inline(__always)
    func matchNameToken(_ names: [String]) -> String? {
        switch current {
        case let .ident(s), let .keyword(s):
            switch names.count {
            case 0: return nil
            case 1: return (s == names[0]) ? s : nil
            case 2: return (s == names[0] || s == names[1]) ? s : nil
            case 3: return (s == names[0] || s == names[1] || s == names[2]) ? s : nil
            default:
                // Uncommon path; fine to do a linear scan here
                return names.contains(s) ? s : nil
            }
        default:
            return nil
        }
    }

    /// Allows turning a DateSpecification into a Date (errors if `.infer` shows up where not allowed).
    @inline(__always)
    func requireAbsolute(_ spec: DateSpecification, _ what: String) throws -> Date {
        switch spec {
        case let .absolute(d): return d
        case .infer:
            throw ParserError.unexpectedToken(current, expected: "\(what): absolute date", at: loc())
        }
    }
}

public extension DateSpecification {
    func asAbsolute(loc: Position) throws -> Date {
        switch self {
        case let .absolute(d): return d
        case .infer:
            throw ParserError.unexpectedToken(.ident("infer"), expected: "absolute date", at: loc)
        }
    }
}
