import Foundation

public extension EntryCompilerParsing {
    @inlinable
    func parseDepreciationBlock(meta: inout [String:String]) throws -> DepreciationConfig {
        var out = DepreciationConfig(
            method: nil,
            usefulLifeYears: nil,
            residualValuePercent: 0,
            residualValueAmount: nil,
            effectiveDate: nil
        )

        advance() // 'depreciation'
        try expect(.lBrace)

        while current != .rBrace && current != .eof {
            if parseDepreciationValuation(into: &meta) { continue }
            if parseUsefulLifeMonths(into: &meta) { continue }
            if parseDepreciationRollforward(into: &meta) { continue }

            switch current {
            case .ident("method"):
                advance(); try expect(.equals)
                guard case let .ident(m) = current else {
                    throw ParserError.unexpectedToken(current, expected: "dep method", at: loc())
                }
                guard let mm = DepreciationMethod(rawValue: m) else {
                    throw ParserError.unexpectedToken(current, expected: "straight_line|sl|ddb|syd|uop", at: loc())
                }
                out.method = mm
                advance()

            case .ident("useful_life_years"), .ident("useful_life"):
                advance(); try expect(.equals)
                guard case let .number(n) = current else {
                    throw ParserError.unexpectedToken(current, expected: "number", at: loc())
                }
                out.usefulLifeYears = n
                advance()

            case .ident("residual_value"):
                advance(); try expect(.lBrace)
                while current != .rBrace && current != .eof {
                    switch current {
                    case .ident("keep_percentage"):
                        advance(); out.residualValuePercent = Decimal(-1)
                    case .ident("percentage"):
                        advance(); try expect(.equals)
                        guard case let .number(n) = current else {
                            throw ParserError.unexpectedToken(current, expected: "number", at: loc())
                        }
                        out.residualValuePercent = n; advance()
                    case .ident("amount"), .ident("value"):
                        advance(); try expect(.equals)
                        guard case let .number(n) = current else {
                            throw ParserError.unexpectedToken(current, expected: "number", at: loc())
                        }
                        out.residualValueAmount = n; advance()
                    default:
                        break
                    }
                }
                try expect(.rBrace)

            case .ident("effective_date"), .ident("commission_date"):
                advance(); try expect(.equals)
                switch current {
                case let .dateLiteral(text):
                    out.effectiveDate = try parseDateLiteral(text, in: .current); advance()
                case .lBrace:
                    out.effectiveDate = try parseDateBlock(tz: .current)
                default:
                    throw ParserError.unexpectedToken(current, expected: "date literal or { … }", at: loc())
                }

            default:
                throw ParserError.unexpectedToken(
                    current,
                    expected: "method/useful_life(_years)/residual_value/effective_date/valuation/rollforward",
                    at: loc()
                )
            }
        }

        try expect(.rBrace)
        return out
    }

    // // back-compat shim (if any callsites still use the old signature)
    // @inlinable
    // func parseDepreciationBlock() throws -> DepreciationConfig {
    //     var sink: [String:String] = [:]
    //     return try parseDepreciationBlock(meta: &sink)
    // }
}
