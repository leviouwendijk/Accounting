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
            if try parseDepreciationValuation(into: &meta) { continue }
            if try parseUsefulLifeMonths(into: &meta) { continue }
            if try parseDepreciationRollforward(into: &meta) { continue }

            switch current {
            case .ident("method"), .keyword("method"):
                advance(); try expect(.equals)
                guard case let .ident(m) = current else {
                    throw ParserError.unexpectedToken(current, expected: "dep method", at: loc())
                }
                guard let mm = DepreciationMethod(rawValue: m) else {
                    throw ParserError.unexpectedToken(current, expected: "straight_line|sl|ddb|syd|uop", at: loc())
                }
                out.method = mm
                advance()

            case .ident("useful_life_years"), .keyword("useful_life_years"),
                .ident("useful_life"),        .keyword("useful_life"):
                advance(); try expect(.equals)
                guard case let .number(n) = current else {
                    throw ParserError.unexpectedToken(current, expected: "number", at: loc())
                }
                out.usefulLifeYears = n
                advance()

            case .ident("residual_value"), .keyword("residual_value"):
                advance(); try expect(.lBrace)
                while current != .rBrace && current != .eof {
                    switch current {
                    case .ident("keep_percentage"), .keyword("keep_percentage"):
                        advance(); out.residualValuePercent = Decimal(-1)
                    case .ident("percentage"), .keyword("percentage"):
                        advance(); try expect(.equals)
                        guard case let .number(n) = current else {
                            throw ParserError.unexpectedToken(current, expected: "number", at: loc())
                        }
                        out.residualValuePercent = n; advance()
                    case .ident("amount"), .keyword("amount"), .ident("value"), .keyword("value"):
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

            case .ident("effective_date"), .keyword("effective_date"),
                 .ident("commission_date"), .keyword("commission_date"):
                advance()
                if current == .equals {
                    // literal: commission_date = 2025-08-07
                    advance()
                    guard case let .dateLiteral(text) = current else {
                        throw ParserError.unexpectedToken(current, expected: "date literal", at: loc())
                    }
                    out.effectiveDate = try parseDateLiteral(text, in: .current)
                    advance()
                } else if current == .lBrace {
                    // block: commission_date { year=… month=… day=… }
                    out.effectiveDate = try parseDateBlock(tz: .current)
                } else if case let .dateLiteral(text) = current {
                    // (optional nicety) allow implicit literal without '='
                    out.effectiveDate = try parseDateLiteral(text, in: .current)
                    advance()
                } else {
                    throw ParserError.unexpectedToken(
                        current,
                        expected: "= <date literal> or { year/month/day }",
                        at: loc()
                    )
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
