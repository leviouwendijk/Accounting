import Foundation

public extension EntryCompilerParsing {
    /// date = <literal|{…}> | date infer <day>
    @inlinable
    func parseDateOrInfer(tz: TimeZone, allowUnixEpoch: Bool = false) throws -> DateSpecification {
        try expect(.ident("date"))
        if current == .equals {
            advance()
            switch current {
            case let .dateLiteral(txt):
                let d = try parseDateLiteral(txt, in: tz); advance()
                return .absolute(d)
            case .lBrace:
                let d = try parseDateBlock(tz: tz)
                return .absolute(d)
            case let .number(n) where allowUnixEpoch:
                let d = Date(timeIntervalSince1970: (n as NSDecimalNumber).doubleValue); advance()
                return .absolute(d)
            default:
                throw ParserError.unexpectedToken(current, expected: "date literal or { … }", at: loc())
            }
        }
        try expect(.ident("infer"))
        guard case let .number(n) = current else {
            throw ParserError.unexpectedToken(current, expected: "number (day of month)", at: loc())
        }
        let day = (n as NSDecimalNumber).intValue
        advance()
        return .infer(day: day)
    }
}
