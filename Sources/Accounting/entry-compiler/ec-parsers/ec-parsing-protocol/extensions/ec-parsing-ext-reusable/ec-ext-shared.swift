import Foundation
import plate

public extension EntryCompilerParsing {
    /// Parse `id = <number>` into a provided slot.
    @inlinable
    func parseId(into slot: inout Int?, what: String = "global id") throws {
        try expect(.keyword("id"))
        try expect(.equals)
        guard case let .number(n) = current else {
            throw ParserError.unexpectedToken(current, expected: "number (\(what))", at: loc())
        }
        slot = (n as NSDecimalNumber).intValue
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
                comps.year = (n as NSDecimalNumber).intValue; advance()
            case .keyword("month"):
                try expect(.keyword("month")); try expect(.equals)
                if case let .ident(s) = current { comps.month = try monthIndex(from: s); advance() }
                else if case let .number(n) = current { comps.month = (n as NSDecimalNumber).intValue; advance() }
                else { throw ParserError.unexpectedToken(current, expected: "identifier or number", at: loc()) }
            case .keyword("day"):
                try expect(.keyword("day")); try expect(.equals)
                guard case let .number(n) = current else { throw ParserError.unexpectedToken(current, expected: "number", at: loc()) }
                comps.day = (n as NSDecimalNumber).intValue; advance()
            default:
                throw ParserError.unexpectedToken(current, expected: "year, month, or day", at: loc())
            }
        }
        try expect(.rBrace)
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = tz
        guard let d = cal.date(from: comps) else {
            throw ParserError.unexpectedToken(current, expected: "valid date", at: loc()) // force throw invalids!
        }
        return d
    }
    
    func parseDateLiteral(_ s: String, in tz: TimeZone) throws -> Date {
        let parts = try s.dateParts()                               // plate
        let format: DateParserFormatting
        if parts[0].count == 4 { format = .yyyyMMdd }               // 2025-01-20
        else if parts[2].count == 4 { format = .ddMMyyyy }          // 20-01-2025
        else { format = .yyyyMMdd }                                  // fallback
        let comps = try format.components(from: parts)               // plate
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = tz
        guard let d = cal.date(from: comps) else {
            throw ParserError.unexpectedToken(.string(s), expected: "valid date literal", at: loc())
        }
        return d
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
