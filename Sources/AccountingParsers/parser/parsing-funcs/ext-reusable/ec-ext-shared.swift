import Foundation
import plate
import Primitives

public extension EntryCompilerParsing {
    /// Parse `id = <number>` into a provided slot.
    @inlinable
    func parseId(into slot: inout Int?, what: String = "global id") throws {
        try expect(.keyword("id"))
        if slot != nil {
            throw ParserError.unexpectedToken(current, expected: "single \(what) directive", at: loc())
        }
        try expect(.equals)
        guard case let .number(n) = current else {
            throw ParserError.unexpectedToken(current, expected: "number (\(what))", at: loc())
        }
        slot = try exactInteger(n)
        advance()
    }

    func parseDateBlock(tz: TimeZone) throws -> Date {
        try expect(.lBrace)
        var comps = DateComponents()
        while current != .rBrace {
            switch current {
            case .keyword("year"):
                try expect(.keyword("year")); try expect(.equals)
                guard case let .number(n) = current else { throw ParserError.unexpectedToken(current, expected: "number", at: loc()) }
                comps.year = try exactInteger(n); advance()
            case .keyword("month"):
                try expect(.keyword("month")); try expect(.equals)
                if case let .ident(s) = current { comps.month = try monthIndex(from: s); advance() }
                else if case let .number(n) = current { comps.month = try exactInteger(n); advance() }
                else { throw ParserError.unexpectedToken(current, expected: "identifier or number", at: loc()) }
            case .keyword("day"):
                try expect(.keyword("day")); try expect(.equals)
                guard case let .number(n) = current else { throw ParserError.unexpectedToken(current, expected: "number", at: loc()) }
                comps.day = try exactInteger(n); advance()
            default:
                throw ParserError.unexpectedToken(current, expected: "year, month, or day", at: loc())
            }
        }
        try expect(.rBrace)
        return try resolveValidatedDate(
            year: comps.year,
            month: comps.month,
            day: comps.day,
            in: tz,
            unexpected: current,
            expected: "valid date"
        )
    }
    
    func parseDateLiteral(_ s: String, in tz: TimeZone) throws -> Date {
        let parts = try s.dateParts()                               // plate
        let format: DateParserFormatting
        if parts[0].count == 4 { format = .yyyyMMdd }               // 2025-01-20
        else if parts[2].count == 4 { format = .ddMMyyyy }          // 20-01-2025
        else { format = .yyyyMMdd }                                  // fallback
        let comps = try format.components(from: parts)               // plate
        return try resolveValidatedDate(
            year: comps.year,
            month: comps.month,
            day: comps.day,
            in: tz,
            unexpected: .string(s),
            expected: "valid date literal"
        )
    }

    /// Canonical finalization for both `.ec` date literals and date blocks.
    /// PartialDate supplies Gregorian component invariants; retain the calendar
    /// round-trip guard to preserve the existing time-zone/date semantics.
    private func resolveValidatedDate(
        year: Int?,
        month: Int?,
        day: Int?,
        in timeZone: TimeZone,
        unexpected token: EntryCompilerToken,
        expected: String
    ) throws -> Date {
        guard let year, let month, let day else {
            throw ParserError.unexpectedToken(token, expected: expected, at: loc())
        }

        do {
            let partial = try PartialDate(year: year, month: month, day: day)
            let date = try partial.resolve(in: timeZone)
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = timeZone
            let resolved = calendar.dateComponents([.year, .month, .day], from: date)
            guard resolved.year == year,
                  resolved.month == month,
                  resolved.day == day else {
                throw ParserError.unexpectedToken(token, expected: expected, at: loc())
            }
            return date
        } catch {
            throw ParserError.unexpectedToken(token, expected: expected, at: loc())
        }
    }
}

// public extension EntryCompilerParsing {
//     func parseDateBlock() throws -> Date {
//         try expect(.lBrace)
//         var comps = DateComponents()
//         while current != .rBrace {
//             switch current {
//             case .keyword("year"):
//                 try expect(.keyword("year")); try expect(.equals)
//                 guard case let .number(n) = current else {
//                     throw ParserError.unexpectedToken(current, expected: "number", at: loc())
//                 }
//                 comps.year = (n as NSDecimalNumber).intValue; advance()

//             case .keyword("month"):
//                 try expect(.keyword("month")); try expect(.equals)
//                 if case let .ident(s) = current {
//                     comps.month = try monthIndex(from: s); advance()
//                 } else if case let .number(n) = current {
//                     comps.month = (n as NSDecimalNumber).intValue; advance()
//                 } else {
//                     throw ParserError.unexpectedToken(current, expected: "identifier or number", at: loc())
//                 }

//             case .keyword("day"):
//                 try expect(.keyword("day")); try expect(.equals)
//                 guard case let .number(n) = current else {
//                     throw ParserError.unexpectedToken(current, expected: "number", at: loc())
//                 }
//                 comps.day = (n as NSDecimalNumber).intValue; advance()

//             default:
//                 throw ParserError.unexpectedToken(current, expected: "year, month, or day", at: loc())
//             }
//         }
//         try expect(.rBrace)
//         return Calendar.current.date(from: comps) ?? Date()
//     }
// }
